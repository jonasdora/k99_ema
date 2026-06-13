


# loading required libraries

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import pyddm
import scipy.stats
import pyddm.plot

print(pyddm.__version__)
print(pyddm.model.HAS_CSOLVE)

# reading in data

file_path_vbdm = 'C:/Users/Jonas Dora/OneDrive - UW/studies/k99.2/data/ddm_input.csv'
df_vbdm = pd.read_csv(file_path_vbdm)

# creating an empty dataframe to store results

results_df = pd.DataFrame()

# define model

# MWS CHANGE: I changed the name of this from "DriftConstant" to
# "DriftValueBias" because "DriftConstant" is already a name of a drift in
# PyDDM, so we don't want it to be confusing to interpret later.
class DriftValueBias(pyddm.models.Drift):
    name = "Constant drift with bias"
    required_parameters = ["drift", "alcbias"] 
    required_conditions = ["value_function"] 
    
    def get_drift(self, conditions, **kwargs):
        return self.drift * conditions['value_function'] + self.alcbias

# define OverlayNonDecisionGaussian class

#class OverlayNonDecisionGaussian(pyddm.Overlay):
#    name = "Add a Gaussian-distributed non-decision time"
#    required_parameters = ["nondectime", "ndsigma"]
#    
#    def apply(self, solution):
#        nondectime = self.nondectime
#        ndsigma = self.ndsigma
#
#        assert ndsigma > 0, "Invalid sigma parameter"
#        times = np.asarray(list(range(-len(solution.choice_upper), len(solution.choice_upper))))*solution.dt
#        weights = scipy.stats.norm(scale=ndsigma, loc=nondectime).pdf(times)
#        if np.sum(weights) > 0:
#            weights /= np.sum(weights)
#        newchoice_upper = np.convolve(weights, solution.choice_upper, mode="full")[len(solution.choice_upper):(2*len(solution.choice_upper))]
#        newchoice_lower = np.convolve(weights, solution.choice_lower, mode="full")[len(solution.choice_upper):(2*len(solution.choice_upper))]
#        return pyddm.Solution(newchoice_upper, newchoice_lower, solution.model,
#                              solution.conditions, solution.undec)
    
subject_session_combinations = df_vbdm[['subject', 'session']].drop_duplicates()

# iterate over subject to fit model to each participant's data and store results in dataframe
for _, row in subject_session_combinations.iterrows():
    subject_id = row['subject']
    session_id = row['session']
    print(f"Processing subject {subject_id}, session {session_id}")

    # filtering data for the current subject and session
    df = df_vbdm[(df_vbdm['subject'] == subject_id) & (df_vbdm['session'] == session_id)].copy()
    df.loc[df['choice'] == 0, 'choice'] = np.nan
    df.loc[df['RT'] < 0.1, 'RT'] = np.nan
    df.loc[df['RT'] > 4, 'RT'] = np.nan 

    overlay = pyddm.OverlayChain(overlays=[
        pyddm.OverlayNonDecision(nondectime=pyddm.Fittable(minval=0, maxval=1)),
        pyddm.OverlayUniformMixture(umixturecoef=.02)
    ])

    # creating the model

    model_constant = pyddm.Model(
        name='DDM model',
        drift=DriftValueBias(drift=pyddm.Fittable(minval=-10, maxval=10), 
                        alcbias=pyddm.Fittable(minval=-5, maxval=5)), 
        noise=pyddm.NoiseConstant(noise=1), 
        bound=pyddm.BoundConstant(B=pyddm.Fittable(minval=.1, maxval=4)), 
        overlay=overlay, 
        choice_names=("alc", "soft"), 
        dx=.001, dt=.001, T_dur=4
    )
    
    df.loc[:, 'choice_nums'] = df['choice'].apply(lambda x : 1.0 if x == 'alc' else 0.0)
    df = df.dropna()

    if len(df) < 120:
        print(f"Skipping subject {subject_id}, session {session_id}: only {len(df)} trials (< 120 required)")
        continue
    
    sample = pyddm.Sample.from_pandas_dataframe(df, rt_column_name='RT', choice_column_name='choice_nums', choice_names=("alc", "soft"))

    fitted_model = pyddm.fit_adjust_model(sample=sample, model=model_constant, verbose=False)
    print(repr(fitted_model))


    # extracting parameters and add to results dataframe

    params = fitted_model.parameters()
    print(params)

    # MWS CHANGE: This is simpler
    negative_log_likelihood = fitted_model.get_fit_result().value
    print(negative_log_likelihood)
    
    hit_boundary = pyddm.hit_boundary(fitted_model)
    print(f"Hit boundary: {hit_boundary}")

    hit_boundary2 = None
    
    if hit_boundary:
        print("Boundary hit. Refitting model with expanded bounds.")

        # MWS CHANGE: Changing this to fit with expanded boundaries in all
        # parameters.  Two reasons: (a) The previous code to detect boundary
        # hits will not detect some of them, because the boundary hits are
        # usually not exactly on the boundary, but maybe .0001 off the
        # boundary. (b) If you hit the boundary on multiple parameters, it will
        # not modify both.  The easiest way around this is just to let all three
        # parameters be bigger.
        model_constant = pyddm.Model(
            name='Refit model',
            drift=DriftValueBias(drift=pyddm.Fittable(minval=-20, maxval=20), 
                                alcbias=pyddm.Fittable(minval=-10, maxval=10)), 
            noise=pyddm.NoiseConstant(noise=1), 
            bound=pyddm.BoundConstant(B=pyddm.Fittable(minval=0.1, maxval=8)), 
            overlay=overlay, 
            choice_names=("alc", "soft"), 
            dx=.001, dt=.001, T_dur=4)
        
        # Refit the model with expanded bounds
        fitted_model = pyddm.fit_adjust_model(sample=sample, model=model_constant, verbose=False)
        
        # Check if boundary is hit after refitting
        hit_boundary2 = pyddm.hit_boundary(fitted_model)
        print(f"After refitting, hit boundary: {hit_boundary2}")
        
        # Update params with new fitted values
        params = fitted_model.parameters()
        
        # MWS CHANGE: This is simpler
        negative_log_likelihood = fitted_model.get_fit_result().value

    model_repr = repr(fitted_model)

    # MWS CHANGE: Generate diagnostic plots for each session to give yourself an
    # intuition of the fits

    f = plt.figure()
    pyddm.plot.plot_fit_diagnostics(model=fitted_model, sample=sample, data_dt=.1, fig=f)
    f.savefig(f"plot_subj{subject_id:02}_sess{session_id:02}.png")
    plt.close(f) 

    new_row = pd.DataFrame({
            'subject': [subject_id],
            'session': [session_id],
            'drift': [params['drift']['drift']], 
            'alcbias': [params['drift']['alcbias']],  
            'B': [params['bound']['B']],  
            'nondectime': [params['overlay']['nondectime']],
 #           'ndsigma': [params['overlay']['ndsigma']],
            'negative_log_likelihood': [negative_log_likelihood],
            'hit_boundary': [hit_boundary],
            'hit_boundary2': [hit_boundary2],
            'repr': [model_repr]
        })


    results_df = pd.concat([results_df, new_row], ignore_index=True)
    print(f"Successfully processed subject {subject_id}, session {session_id}")
# saving results to CSV

results_df.to_csv('ddm_results.csv', index=False)

print("Processing complete. Results saved to ddm_results.csv")
