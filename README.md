# Halda River external validation package

This package contains an external framework validation of AAH-AquaPredict using a one-year Halda River 2025 water-quality dataset.

Important interpretation: the Halda dataset does not include an observed water-quality class label. WQI-derived relative classes were created and used as the external classification endpoint. Therefore, this analysis should be described as framework-level external validation using an independent WQI-derived Halda endpoint, not as direct validation against independently field-labelled water-quality classes.

Rows raw: 367
Duplicate date rows removed: 2
Unique daily observations: 365
Temporal train period: Jan-Oct 2025, n=304
Temporal validation period: Nov-Dec 2025, n=61

AAH-AquaPredict external temporal validation accuracy: 1.000
AAH-AquaPredict external temporal validation macro-F1: 1.000
