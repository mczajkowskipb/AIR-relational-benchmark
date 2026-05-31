#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass
from itertools import combinations
from typing import Optional

import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, balanced_accuracy_score, f1_score, matthews_corrcoef
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier


@dataclass
class GenePairModel:
    method_id: str
    pairs: list[tuple[str, str]]
    positive_label: str
    negative_label: str
    classifier: Optional[object] = None
    notes: str = ""


def _safe_feature_matrix(x: pd.DataFrame) -> pd.DataFrame:
    x = x.copy()
    x = x.apply(pd.to_numeric, errors="coerce")
    x = x.fillna(x.median(axis=0))
    return x


def tsp_pair_scores(x_train: pd.DataFrame, y_train: pd.Series, positive_label: str) -> pd.DataFrame:
    y = y_train.astype(str)
    pos_mask = y == positive_label
    neg_mask = ~pos_mask

    rows = []
    cols = list(x_train.columns)

    for a, b in combinations(cols, 2):
        rel = x_train[a].values > x_train[b].values
        p_pos = float(np.mean(rel[pos_mask.values]))
        p_neg = float(np.mean(rel[neg_mask.values]))
        diff = p_pos - p_neg

        if diff >= 0:
            g1, g2 = a, b
            direction = "gt_positive"
        else:
            g1, g2 = b, a
            direction = "gt_positive"
            diff = -diff

        rows.append((g1, g2, abs(diff), direction))

    out = pd.DataFrame(rows, columns=["gene1", "gene2", "score", "direction"])
    out = out.sort_values("score", ascending=False).reset_index(drop=True)
    return out


def encode_pairs(x: pd.DataFrame, pairs: list[tuple[str, str]], ternary: bool = True) -> pd.DataFrame:
    enc = {}
    for g1, g2 in pairs:
        if ternary:
            enc[f"{g1}|{g2}"] = np.sign(x[g1].values - x[g2].values).astype(int)
        else:
            enc[f"{g1}|{g2}"] = (x[g1].values > x[g2].values).astype(int)
    return pd.DataFrame(enc, index=x.index)


def fit_py_tsp(
    x_train: pd.DataFrame,
    y_train: pd.Series,
    positive_label: str,
    top_pairs: int = 1,
) -> GenePairModel:
    x_train = _safe_feature_matrix(x_train)
    negative_label = [z for z in sorted(y_train.astype(str).unique()) if z != positive_label][0]

    scores = tsp_pair_scores(x_train, y_train, positive_label)
    scores = scores.head(top_pairs)
    pairs = list(zip(scores["gene1"], scores["gene2"]))

    return GenePairModel(
        method_id="py_tsp",
        pairs=pairs,
        positive_label=positive_label,
        negative_label=negative_label,
        notes=f"Python TSP-style top_pairs={top_pairs}",
    )


def predict_py_tsp(model: GenePairModel, x_test: pd.DataFrame) -> tuple[np.ndarray, np.ndarray]:
    x_test = _safe_feature_matrix(x_test)
    enc = encode_pairs(x_test, model.pairs, ternary=False)

    votes = enc.values.sum(axis=1)
    pred = np.where(votes > (len(model.pairs) / 2), model.positive_label, model.negative_label)

    # hard vote proportion, not calibrated probability
    score = votes / max(1, len(model.pairs))
    return pred, score


def fit_py_tsp_svm(
    x_train: pd.DataFrame,
    y_train: pd.Series,
    positive_label: str,
    top_pairs: int = 25,
    kernel: str = "linear",
) -> GenePairModel:
    x_train = _safe_feature_matrix(x_train)
    negative_label = [z for z in sorted(y_train.astype(str).unique()) if z != positive_label][0]

    scores = tsp_pair_scores(x_train, y_train, positive_label)
    pairs = list(zip(scores.head(top_pairs)["gene1"], scores.head(top_pairs)["gene2"]))
    enc = encode_pairs(x_train, pairs, ternary=True)

    clf = SVC(kernel=kernel, C=1.0, probability=True, random_state=42)
    clf.fit(enc, y_train.astype(str))

    return GenePairModel(
        method_id="py_tsp_svm",
        pairs=pairs,
        positive_label=positive_label,
        negative_label=negative_label,
        classifier=clf,
        notes=f"Python TSP pair encoding + SVM; top_pairs={top_pairs}; kernel={kernel}",
    )


def fit_py_tsp_rf(
    x_train: pd.DataFrame,
    y_train: pd.Series,
    positive_label: str,
    top_pairs: int = 50,
) -> GenePairModel:
    x_train = _safe_feature_matrix(x_train)
    negative_label = [z for z in sorted(y_train.astype(str).unique()) if z != positive_label][0]

    scores = tsp_pair_scores(x_train, y_train, positive_label)
    pairs = list(zip(scores.head(top_pairs)["gene1"], scores.head(top_pairs)["gene2"]))
    enc = encode_pairs(x_train, pairs, ternary=True)

    clf = RandomForestClassifier(
        n_estimators=50,
        max_depth=3,
        random_state=42,
        n_jobs=1,
        class_weight=None,
    )
    clf.fit(enc, y_train.astype(str))

    return GenePairModel(
        method_id="py_tsp_rf",
        pairs=pairs,
        positive_label=positive_label,
        negative_label=negative_label,
        classifier=clf,
        notes=f"Python TSP pair encoding + RF; top_pairs={top_pairs}; trees=50",
    )


def reos_pair_scores(
    x_train: pd.DataFrame,
    y_train: pd.Series,
    positive_label: str,
    cutoff: float = 0.85,
) -> pd.DataFrame:
    y = y_train.astype(str)
    pos_mask = y == positive_label
    neg_mask = ~pos_mask

    rows = []
    cols = list(x_train.columns)

    for a, b in combinations(cols, 2):
        rel_pos = x_train.loc[pos_mask.values, a].values > x_train.loc[pos_mask.values, b].values
        rel_neg = x_train.loc[neg_mask.values, a].values > x_train.loc[neg_mask.values, b].values

        pos_gt = np.mean(rel_pos)
        neg_gt = np.mean(rel_neg)

        # reversed-expression-order-like: strong opposite orientation
        score1 = min(pos_gt, 1.0 - neg_gt)
        score2 = min(1.0 - pos_gt, neg_gt)

        if score1 >= cutoff:
            rows.append((a, b, score1))
        elif score2 >= cutoff:
            rows.append((b, a, score2))

    if not rows:
        # fallback: use TSP scores if strict REO cutoff gives no pairs
        tsp = tsp_pair_scores(x_train, y_train, positive_label)
        return tsp[["gene1", "gene2", "score"]].head(25)

    out = pd.DataFrame(rows, columns=["gene1", "gene2", "score"])
    out = out.sort_values("score", ascending=False).reset_index(drop=True)
    return out


def fit_py_reos(
    x_train: pd.DataFrame,
    y_train: pd.Series,
    positive_label: str,
    top_pairs: int = 25,
    cutoff: float = 0.85,
) -> GenePairModel:
    x_train = _safe_feature_matrix(x_train)
    negative_label = [z for z in sorted(y_train.astype(str).unique()) if z != positive_label][0]

    scores = reos_pair_scores(x_train, y_train, positive_label, cutoff=cutoff)
    pairs = list(zip(scores.head(top_pairs)["gene1"], scores.head(top_pairs)["gene2"]))

    return GenePairModel(
        method_id="py_reos",
        pairs=pairs,
        positive_label=positive_label,
        negative_label=negative_label,
        notes=f"Python REO-style voting; top_pairs={top_pairs}; cutoff={cutoff}",
    )


def predict_py_reos(model: GenePairModel, x_test: pd.DataFrame) -> tuple[np.ndarray, np.ndarray]:
    return predict_py_tsp(model, x_test)


def fit_py_reos_svm(
    x_train: pd.DataFrame,
    y_train: pd.Series,
    positive_label: str,
    top_pairs: int = 25,
    cutoff: float = 0.85,
) -> GenePairModel:
    x_train = _safe_feature_matrix(x_train)
    negative_label = [z for z in sorted(y_train.astype(str).unique()) if z != positive_label][0]

    scores = reos_pair_scores(x_train, y_train, positive_label, cutoff=cutoff)
    pairs = list(zip(scores.head(top_pairs)["gene1"], scores.head(top_pairs)["gene2"]))
    enc = encode_pairs(x_train, pairs, ternary=True)

    clf = SVC(kernel="linear", C=1.0, probability=True, random_state=42)
    clf.fit(enc, y_train.astype(str))

    return GenePairModel(
        method_id="py_reos_svm",
        pairs=pairs,
        positive_label=positive_label,
        negative_label=negative_label,
        classifier=clf,
        notes=f"Python REO pair encoding + SVM; top_pairs={top_pairs}; cutoff={cutoff}",
    )


def predict_ml_model(model: GenePairModel, x_test: pd.DataFrame) -> tuple[np.ndarray, np.ndarray]:
    x_test = _safe_feature_matrix(x_test)
    enc = encode_pairs(x_test, model.pairs, ternary=True)

    pred = model.classifier.predict(enc)

    if hasattr(model.classifier, "predict_proba"):
        prob = model.classifier.predict_proba(enc)
        classes = list(model.classifier.classes_)
        if model.positive_label in classes:
            score = prob[:, classes.index(model.positive_label)]
        else:
            score = np.full(len(pred), np.nan)
    else:
        score = np.full(len(pred), np.nan)

    return pred.astype(str), score


def fit_model(method_id: str, x_train: pd.DataFrame, y_train: pd.Series, positive_label: str) -> GenePairModel:
    if method_id == "py_tsp":
        return fit_py_tsp(x_train, y_train, positive_label, top_pairs=1)
    if method_id == "py_tsp_svm":
        return fit_py_tsp_svm(x_train, y_train, positive_label, top_pairs=25, kernel="linear")
    if method_id == "py_tsp_rf":
        return fit_py_tsp_rf(x_train, y_train, positive_label, top_pairs=50)
    if method_id == "py_reos":
        return fit_py_reos(x_train, y_train, positive_label, top_pairs=25, cutoff=0.85)
    if method_id == "py_reos_svm":
        return fit_py_reos_svm(x_train, y_train, positive_label, top_pairs=25, cutoff=0.85)

    raise ValueError(f"Unsupported method_id: {method_id}")


def predict_model(model: GenePairModel, x_test: pd.DataFrame) -> tuple[np.ndarray, np.ndarray]:
    if model.method_id in {"py_tsp", "py_reos"}:
        return predict_py_tsp(model, x_test)
    return predict_ml_model(model, x_test)


def compute_metrics(y_true: pd.Series, y_pred: np.ndarray, score: np.ndarray, positive_label: str) -> dict:
    y_true_s = y_true.astype(str).values
    y_pred_s = np.asarray(y_pred).astype(str)

    out = {
        "accuracy": accuracy_score(y_true_s, y_pred_s),
        "balanced_accuracy": balanced_accuracy_score(y_true_s, y_pred_s),
        "macro_f1": f1_score(y_true_s, y_pred_s, average="macro", zero_division=0),
        "mcc": matthews_corrcoef(y_true_s, y_pred_s),
    }

    return out
