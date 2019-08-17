#!/usr/bin/env python

import numpy as np
import pandas as pd
import imageio

import plotly.offline as off
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots

import metrics as mtc


############################
#   Define norms
############################
# create_bounding_box(df_, "graph", "fro", percentage=True, log10=True,
#                     color="LightSalmon", title="X-Subject")
def create_bounding_box(df, column, metric, df2=None, df2_query=None,
                        df2_query_cols=[], percentage=True, log10=False,
                        percentiles=[25, 50, 75], color="Blue",
                        title="", layer="below"):
    diffs = []
    # If we're not comparing to a reference data frame, use the original
    if df2 is None:
        df2 = df

    # For every row in our dataframe...
    for idx, r1 in df.iterrows():
        # If we plan to filter our dataframe...
        if df2_query:
            # Construct the query from the provided query strings and columns
            qvals = [r1[qc] for qc in df2_query_cols]
            tmp_df2 = df2.query(df2_query.format(*qvals))
        else:
            tmp_df2 = df2

        # For every row in our pre-filtered second dataframe
        for jdx, r2 in tmp_df2.iterrows():
            # Compute the distance of the target column using the chosen metric
            tmp_diff = mtc.metrics[metric](r1[column], r2[column])

            # If we want percentages, normalize this by the auto-norm
            if percentage:
                diffs += [100.0 * tmp_diff / r1['{0} (self)'.format(metric)]]
            else:
                diffs += [tmp_diff]

    # Get percentiles for the range of values seen
    diff_range = np.percentile(diffs, percentiles)

    # If this will eventually be plotted on log-scale data, scale the values
    if log10:
        diff_range = np.log10(diff_range + 1)

    # Verify that we have 3 percentiles to show
    assert(len(percentiles) == 3)

    # Create the boundingrectangle and mid-line
    shapes = [go.layout.Shape(type="rect", xref="paper", yref="y",
                              x0=0,    y0=diff_range[0],
                              x1=0.98, y1=diff_range[-1],
                              fillcolor=color, opacity=0.5,
                              layer=layer, line_width=0),
              go.layout.Shape(type="line", xref="paper", yref="y",
                              x0=0,    y0=diff_range[1],
                              x1=0.98, y1=diff_range[1],
                              line={'color': color, 'width': 4,
                                    "dash": "dash"},
                              opacity=1.0, layer=layer)
              ]

    # Label the shape-annotations
    annotations = [
        go.layout.Annotation(x=0.98, xanchor='right', xref="paper",
                             y=diff_range[-1], yanchor='bottom', yref="y",
                             font={'color': color}, text=title, ax=0, ay=0),
        go.layout.Annotation(x=0.995, y=diff_range[-1], font={'color': color},
                             xref="paper", yref="y", text="Q3", ax=0, ay=0),
        go.layout.Annotation(x=0.995, y=diff_range[0], font={'color': color},
                             xref="paper", yref="y", text="Q1", ax=0, ay=0)
                   ]

    return shapes, annotations


def set_plot_ticks(lower=0, upper=200, log10=True):
    tick_max = 100
    while tick_max < upper:
        tick_max += 100
    tickvals = np.append(np.array([0, 10, 50]),
                         np.linspace(100, tick_max, num=tick_max/100.0))

    ticktext = ["{0} %".format(tv) for tv in tickvals]
    if log10:
        tickvals = np.log10(tickvals + 1)
    return tickvals, ticktext

"""


#%%
percdiff = []
_df_ub = df.loc[df['noise_type'] != df['noise_type']].loc[df["os"] == "ubuntu"]
_df_al = df.loc[df['noise_type'] != df['noise_type']].loc[df["os"] == "alpine"]

for idx, rw1 in _df_ub.iterrows():
    for jdx, rw2 in _df_al.loc[df['sub'] == rw1['sub']].iterrows():
        diff = norms[met](rw1.graph, rw2.graph)
        percdiff += [100.0*diff/rw1['{0} (self)'.format(met)]]
os_diff_range = np.percentile(percdiff, [25, 50, 75])

col = "gray"
shapes += [
    # The 25-75 box
    go.layout.Shape(
        type="rect", xref="paper", yref="y",
        x0=0,    y0=os_diff_range[0],
        x1=0.98, y1=os_diff_range[-1],
        fillcolor=col, opacity=0.5,
        layer="below", line_width=0),
    #The median line
    go.layout.Shape(
        type="line", xref="paper", yref="y",
        x0=0,    y0=os_diff_range[1],
        x1=0.98, y1=os_diff_range[1],
        line={'color':col, 'width':3, 'dash':'dash'},
        opacity=1, layer="above")
]

annotations += [
    go.layout.Annotation(
        x=0.98, xanchor='right', y=os_diff_range[-1], yanchor='bottom',
        xref="paper", yref="y", font={'color':col},
        text="X-OS",
        align="left", ax=0, ay=0)
]


#%%
cord = {"noise_type": ['python_mca', 'python_rr', 'full_rr', 'independent', 'single']}


#%%
png_outpath = '/data/RocklandSample/derivatives/mca/pngs/{0}_summary.png'.format(met)

title = "Differences in Monte Carlo Arithmetic Injected Structural Connectomes"

df_['log {0}'.format(distance)] = np.log10(df_[distance].astype(float)+1)
fig = px.box(df_, y="log {0}".format(distance), x='sub', color='noise_type',
                points='outliers', notched=False, boxmode="group",
                hover_data=['simulation_id'], title=title, category_orders=cord)

# fig = px.violin(df_, y='log {0}'.format(distance), x='sub', color='noise_type',
#                 points='outliers', box=False, violinmode='group', category_orders=cord,
#                 hover_data=['simulation_id'], title=title)


def set_ticks(lower=0, upper=200, log10=True):
    tick_max = 100
    while tick_max < upper:
        tick_max += 100
    tickvals = np.append(np.array([0, 10, 50]),
                         np.linspace(100, tick_max, num=tick_max/100.0))

    ticktext = ["{0} %".format(tv) for tv in tickvals]
    if log10:
        tickvals = np.log10(tickvals + 1)
    return tickvals, ticktext
    
tickvals, ticktext = set_ticks(upper=df_[distance].max(), log10=log10_status)
fig.update_layout(yaxis={"tickvals": tickvals,
                         "ticktext": ticktext})
fig.update_layout(shapes=shapes, annotations=annotations,
                  legend={'y':0.9, 'yanchor': 'top',
                          'x':0.9, 'xanchor': 'right'})


# fig.update_layout(title=title, height=750, width=1350, font=dict(size=20),
#                   yaxis={"title": "{0} (% Deviation)".format(met_names[met]),
#                          "zerolinewidth": 0,
#                          "showline": False,
#                          "range": [-5, df_[distance].max() + 10]},
#                   xaxis={"title": "Subject",
#                          "zerolinewidth": 0,
#                          "showline": False})
fig.show()
# fig.write_image(png_outpath)
# fig.write_image(png_outpath.replace('.png', '.pdf'))
# off.plot(fig, filename=png_outpath.replace('.png', '.html'))


#%%
# The below values were picked for the Frobenius norm
# ss = 'A00035940'
ss = 'A00057725'

df_ss = df_.query('sub == "{0}" and noise_type == "rr"'.format(ss))
modes = df_ss[distance].value_counts().sort_index().to_dict()
mkeys = sorted(modes.keys())

keylocs = [1, 2, 4, 5, 0, 8, 10, 11, 16]

refvol = 4

graphs_to_plot = []
subplot_titles = []
for k in keylocs:
    loc = mkeys[k]
    graphs_to_plot += [df_ss[df_ss[distance] == loc].iloc[0]['graph']]
    if k:
        subplot_titles += ["%d / 100 (%.3f %%)" % (modes[loc], loc)]
    else:
        subplot_titles += ["reference"]


#%%
png_outpath = '/data/RocklandSample/derivatives/mca/pngs/{0}_{1}'.format(met, ss)

axis_template = dict(showgrid = False, zeroline = False,
                     showticklabels = False, ticks = '')

ref_template = dict(mirror=True, showline=True,
                    linewidth=6, linecolor='orange')

fig = make_subplots(rows=3, cols=3,
                    vertical_spacing=0.05,
                    horizontal_spacing=0.03,
                    subplot_titles=subplot_titles)

for idx, gtp in enumerate(graphs_to_plot):
    r, c = int((idx)/ 3) + 1, int((idx) % 3)+1 
    modif = '' if not idx else str(idx + 1)
    if idx == refvol:
        dat = np.log10(gtp+1)
    else:
        dat = gtp - graphs_to_plot[refvol]
        dat = np.sign(dat)*np.log10(np.abs(dat) + 1)

    trace = go.Heatmap(z=dat, coloraxis="coloraxis")
    fig.append_trace(trace, row=r, col=c)
    for k in axis_template:
        fig['layout']['xaxis'+modif][k] = axis_template[k]
        fig['layout']['yaxis'+modif][k] = axis_template[k]
    
    if idx == refvol:
        for k in ref_template:
            fig['layout']['xaxis'+modif][k] = ref_template[k]
            fig['layout']['yaxis'+modif][k] = ref_template[k]

    fig['layout']['yaxis'+modif]['autorange'] = "reversed"

title = 'Error-Induced Deviations from Reference Connectome (Subject {0})'.format(ss)
fig.update_coloraxes(dict(colorscale=px.colors.diverging.RdBu[::-1],
                          showscale=True, cmin=0, cmid=1.5, cmax=3,
                          colorbar=dict(tickvals=[0, 3],
                                        title="Connectivity Strength",
                                        ticktext=['no difference',
                                                  'stronger'])))

fig.update_layout(title=title, height=1500, width=1600, font=dict(size=26))
for idx, anno in enumerate(fig.layout.annotations):
    fig.layout.annotations[idx]['font']['size'] = 28
fig.show()
fig.write_image(png_outpath + '_panel.png')


#%%
png_outpath = '/data/RocklandSample/derivatives/mca/pngs/{0}'.format(ss)

axis_template = dict(showgrid = False, zeroline = False,
                     showticklabels = False, ticks = '',
                     autorange="reversed")

df_ss = df_.query('sub == "{0}" and noise_type == "rr"'.format(ss))
modes = df_ss[distance].value_counts().sort_index().to_dict()
mkeys = sorted(modes.keys())

pngs = []
for idx, k in enumerate(mkeys):
    g = df_ss[df_ss[distance] == k].iloc[0]['graph']
    t = "Difference from Reference: %.3f %%" % (k)

    dat = np.log10(g+1)
    trace = go.Heatmap(z=dat, colorscale=px.colors.diverging.RdBu[::-1],
                       showscale=False, zmin=0, zmid=1.75, zmax=3.5)
    
    single = go.Figure(data=trace)
    title = [go.layout.Annotation(x=0.5, y=1.1, font={"size":22},
                                  xref="paper", yref="paper",
                                  text=t, ax=0, ay=0)]
    single.update_layout(annotations = title, yaxis=axis_template)

    fname = png_outpath + "_{0}.png".format(idx)
    pngs += [fname]
    single.write_image(fname, format='png')


#%%
images = []
for filename in pngs:
    images.append(imageio.imread(filename))
imageio.mimsave(png_outpath + ".gif", images, duration=0.3)


#%%



"""