This project is an attempt to visualize cytometry data using UMAP and
Bokeh for interactive plotting. The project is structured to allow for
efficient computation and caching of intermediate results, leveraging
GPU acceleration with Nvidia cuML.

The following acted as a prompt for the AI (Gemini 2.5 Pro) to generate the code.
It only generated the initial draft, though.

Here is a plot that was generated with the cyto_plot program:

![Screenshot of the interactive UMAP plot](https://raw.githubusercontent.com/plops/cytometry-umap-plot/main/img/plot.png)


I want to experiment cytometry data and UMAP

I downloaded a dataset from http://flowrepository.org/id/FR-FCM-Z6UG

```
4.6M Oct  9  2023  Spleenocytes_Tcells_Vaccinated_GK15__3_009.fcs
4.6M Oct  9  2023  Spleenocytes_Tcells_Vaccinated_GK15__2_007.fcs
4.8M Oct  9  2023  Spleenocytes_Tcells_Vaccinated_Saline_004.fcs
4.8M Oct  9  2023  Spleenocytes_Tcells_Vaccinated_GK15_006.fcs
3.7M Oct  9  2023 'Spleenocytes_Tcells_FMO- no CD4 staining_002.fcs'
7.0M Oct  9  2023  Spleenocytes_Tcells_Rag2KO_005.fcs
3.7M Oct  9  2023  Spleenocytes_Tcells_Unstained_control_001.fcs
4.5M Oct  9  2023  Spleenocytes_Tcells_Vaccinated_aCD8_003.fcs
```

The topic of the research is stated as:
Validate the Leishmania donovani LST leishmanin antigen in immune animals.

Give me instructions on how to start new python project with uv.
What dependencies are required to load the files?
Use Nvidia cuml for UMAP on an NVidia GPU.

Intermediate results shall be stored in cache files between runs, so that I can run the script multiple times and I don't have to wait for compute intensive steps.

Eventually I want to use umap.plot.interactive to plot a bokeh plot (in HTML format).

Make sure configuration options are stored in a good way and the architecture follows industry standard.

This initializes the project and adds the dependencies:

```
uv init cyto-plot
cd cyto-plot
uv add readfcs ruff "cuml-cu12" "cudf-cu12" "umap-learn[plot]" matplotlib bokeh joblib pandas numpy
```

The Joblib library provides a simple way to avoid re-running computationally expensive steps this using the Memory class and the @memory.cache decorator