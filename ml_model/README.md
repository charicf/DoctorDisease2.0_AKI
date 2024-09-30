# Acknowledgement
The code found in this directory is based on that created by Vagliano, Hsu, and Schut as described in:

[Machine Learning, Clinical Notes and Knowledge Graphs for Early Prediction of Acute Kidney Injury in the Intensive Care](https://ebooks.iospress.nl/doi/10.3233/SHTI210926):

    @inproceedings{Vagliano:2021,
         author = {Vagliano, Iacopo and Hsu, Wei-Hsiang and Schut, Martijn C},
         title = {Machine Learning, Clinical Notes and Knowledge Graphs for Early Prediction of Acute Kidney Injury in the Intensive Care},
         booktitle = {Informatics and Technology in Clinical Care and Public Health},
         series = {Studies in health technology and informatics},
         pages = {329--332},
         DOI = {10.3233/SHTI210926},
         volume = {289},
         year = {2022},
         URL = {https://doi.org/10.3233/SHTI210926},
    }

Additionally, as described in their own acknowledgements:

> We thank [Miguel A. Rios Ganoa](https://github.com/mriosb08) for the help to extract the clinical notes.
The `preprocessing.ipynb` script reuses and adapts code from the [MIMIC-III Benchmarks](https://github.com/YerevaNN/mimic3-benchmarks) repository to convert the MIMIC III extracted data to the proper format. Most notably we use a different set of clinical features as input. The `extract_text.ipynb` notebook extends the MIMIC-III Benchmarks to be used not only with clinical features, but also with text. This notebook is partly based on the [Pre-trained Text Representations with Knowledge Bases for Mortality Prediction](https://github.com/Sep905/pre-trained_wv_with_kb), but focus on a different populations and outcome (AKI instead of mortality).

-- <cite> Vagliano, Hsu, and Schut </cite>
