# General Import
import os
import sys

# Data science import
import pickle
import numpy as np

# Sklearn import
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer

# Add the directory containing your module to the Python path (wants absolute paths)
# Here we add to the path everything in the top level
# Since the code will be called from generate_jobs.bash the path that needs to be added is the
# one from the bash script (top level)
scriptpath = "."
sys.path.append(os.path.abspath(scriptpath))

# Common import shared across analysis
import commons
from commons import classify_loso, print_summary
from commons import load_pickle, find_best_model, filter_dataframe
from sklearn.svm import SVC

# This will be given by the srun in the bash file
# Get the argument
EPOCHS = {"ind","emf5","eml5","ec8"} # to compare against baseline
GRAPHS = ["aec", "pli", "both"]

clf=SVC(max_iter=10000, kernel='linear', C=0.1)

for graph in GRAPHS:
    for epoch in EPOCHS:
        final_acc_filename = commons.OUTPUT_DIR + f"FINAL_MODEL_{graph}_ec1_vs_{epoch}_raw.pickle"

        if graph != "both":
            print (f"MODE {graph}")
            print(f"FINAL SVC Model at Graph {graph} at ec1 vs {epoch}")
            X, y, group = filter_dataframe(graph, epoch)

        if graph == "both":
            print (f"MODE {graph}")
            print(f"FINAL SVC Model at Graph {graph} at ec1 vs {epoch}")
            X_pli, y_pli, group_pli = filter_dataframe('pli', epoch)
            X_aec, y_aec, group_aec = filter_dataframe('aec', epoch)
            X = np.hstack((X_aec,X_pli))
            if np.array_equal(y_aec, y_pli):
                print("Y-values equal")
                y= y_aec
            if np.array_equal(group_aec, group_pli):
                print("group-values equal")
                group= group_aec

        #build pipeline with best model
        pipe = Pipeline([
            ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
            ('scaler', StandardScaler()),
            ('CLF', clf)])

        accuracies, cms = classify_loso(X, y, group, pipe)

        clf_data = {
            'accuracies': accuracies,
            #'f1s': f1s,
            'cms': cms,
            #'best_params': best_params,
        }

        final_acc_file = open(final_acc_filename, 'ab')
        pickle.dump(clf_data, final_acc_file)
        final_acc_file.close()
        print(sum(accuracies))
