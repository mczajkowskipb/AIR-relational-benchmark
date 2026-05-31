# wucc009 gene-pair methods probe

This file summarizes the external repository probe.

External source: `wucc009/Implementation-and-comparison-of-gene-pair-methods`.

The external repository is not vendored into this benchmark repository. It is cloned under `external/` for local inspection only.

## Notebook summary

### `Gene_pair_methods_R.ipynb`

- Cells: 39
- Code cells: 20
- Markdown cells: 19
- Imports: none detected
- Function/class definitions: none detected
- Keyword hits: GER, TSP, k-TSP, KTSP, TSPG, ML, gene pair, pair

Headings:

- # 1、Data Processing
- ### 1.1 Data preprocessing
- ### 1.2 Split training, testing, and external independent validation sets
- # 2、Gene pair methods based on gene expression values
- ### 2.1 GERs
- #### 2.1.1 Train
- #### 2.1.2 Test
- # 3、Gene pair methods based on gene ranking relationships
- ### 3.1 k-TSP
- #### 3.1.1 Train
- #### 3.1.2 Test
- ### 3.2 TSPG
- #### 3.2.1 Train
- #### 3.2.2 Test
- # 4、Plot

### `Gene_pair_methods_python.ipynb`

- Cells: 95
- Code cells: 50
- Markdown cells: 45
- Imports: itertools, joblib, matplotlib, minepy, numpy, pandas, pymrmr, scipy, sklearn, tqdm, xgboost
- Function/class definitions: function:Chi2_feature_importance_rank, function:MIC_feature_importance_rank, function:MIC_score, function:RF_feature_importance_rank, function:adjust_gene_pairs, function:calculate_accuracy, function:calculate_average_order_diff, function:degree_of_reversal_rank, function:duplicate_removal, function:feature_coding, function:feature_importance_rank, function:gene_pairs_extraction, function:gene_pairs_subset_selection, function:mRMR_feature_importance_rank, function:neg, function:neg_calculate_counts, function:pos, function:pos_calculate_counts, function:reverse_gene_pairs, function:selection
- Keyword hits: TSP, k-TSP, KTSP, SVM, REO, REOs, ML, gene pair, pair

Headings:

- # 1、Gene pair methods based on gene ranking relationships
- ### 1.1 TSP
- #### 1.1.1 Train
- ##### 1.1.1.1 Import data and extract positive and negative matrices
- ##### 1.1.1.2 Calculate number of samples and create a matrix with all gene pairwise combinations, each row containing two gene symbols
- ##### 1.1.1.3 For positive and negative matrices, calculate the count of times the first gene is less than the second gene in each row, then divide by the number of samples (assign to columns 3 and 4)
- ##### 1.1.1.4 Subtract column 4 from column 3 and assign the result to column 5, swap the gene positions in rows with negative values to ensure the smaller gene comes first, then take the absolute value of column 5, sort, and delete columns 3 and 4
- ##### 1.1.1.5 Obtain the Top scoring pair
- #### 1.1.2 Test
- ### 1.2 k-TSP+SVM
- #### 1.2.1 Train
- ##### 1.2.1.1 Feature encoding
- ##### 1.2.1.2 Model construction
- #### 1.2.2 Test
- ### 1.3 REOs
- #### 1.3.1 Train
- ##### 1.3.1.1 Obtain reversed gene pairs
- ##### 1.3.1.2 Sort reversed gene pairs in descending order of reversal degree
- ##### 1.3.1.3 Optimal reversed gene pair subset selection
- #### 1.3.2 Test
- ### 1.4 REOs+ML
- #### 1.4.1 Train
- ##### 1.4.1.1 Feature encoding
- ##### 1.4.1.2 Feature selection
- ##### 1.4.1.3 Model construction and saving
- #### 1.4.2 Test
- ### 1.5 TSP+ML
- #### 1.5.1 Train
- ##### 1.5.1.1 Preliminary feature extraction
- ##### 1.5.1.2 Feature encoding
- ##### 1.5.1.3 Feature importance ranking
- ##### 1.5.1.4 Feature, algorithm, and optimal parameter selection
- ##### 1.5.1.5 Model construction
- #### 1.5.2 Test

## Initial method candidates

| candidate | source notebook | status | next action |
|---|---|---:|---|
| TSP | Python notebook | PROBE_ONLY | Inspect whether code can be converted to callable function. |
| k-TSP+SVM | Python notebook | PROBE_ONLY | Inspect input assumptions and classifier interface. |
| REOs | Python notebook | PROBE_ONLY | Inspect whether method is supervised, diagnostic, or rule-discovery oriented. |
| REOs+ML | Python notebook | PROBE_ONLY | Inspect feature-generation stage and downstream ML model. |
| TSP+ML | Python notebook | PROBE_ONLY | Inspect feature-generation stage and downstream ML model. |
| GERs | R notebook | PROBE_ONLY | Inspect separately; may require R wrapper rather than Python. |
| TSPG | R notebook | PROBE_ONLY | Inspect separately. |

## Decision rule

A method should enter the AIR benchmark only if it can be converted into a callable train/predict wrapper without hidden manual notebook state.
