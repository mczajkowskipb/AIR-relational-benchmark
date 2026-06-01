#!/usr/bin/env python3

import numpy as np
from pyrrm import relative_relation_metric
from sklearn.neighbors import KNeighborsClassifier

X = np.array([
    [1.0, 2.0, 3.0],
    [1.1, 2.1, 3.1],
    [3.0, 2.0, 1.0],
    [3.1, 2.1, 1.1],
])
y = np.array(["A", "A", "B", "B"])

clf = KNeighborsClassifier(n_neighbors=1, metric=relative_relation_metric)
clf.fit(X, y)

pred = clf.predict(X)

print("relative_relation_metric demo:", relative_relation_metric(X[0], X[2]))
print("pred:", pred.tolist())
print("ok:", bool((pred == y).all()))
