Based `.fcs` column names ('FSC-A', 'FSC-H', 'FSC-W', 'SSC-A',
'SSC-H', 'SSC-W', 'BV421-A', 'BV510-A', 'BV605-A', 'BV650-A', 'CD4',
'BB515-A', 'CD8', 'PE-CF594-A', 'Live/Dead', 'CD3', 'APC-R700-A',
'CD45'), the paper's Figure 2, and the detailed
`LST_Depletion_check_14-Feb-2022.wsp` FlowJo workspace file, here is
the step-by-step procedure for processing the flow cytometry data to
generate the dot plots shown in Figure 2B of
https://pmc.ncbi.nlm.nih.gov/articles/PMC10622560/.

The overall goal is to isolate the population of single, live T-cells
(CD3+) from splenocytes and then analyze the presence of CD4+ and CD8+
subsets within that population to check the antibody depletion
efficacy.

## Initial Processing: Compensation

Before any gating, the raw data from the `.fcs` files must be
compensated. The `.wsp` file contains an acquisition-defined
**spillover matrix** that corrects for the spectral overlap between
different fluorochromes. This is a crucial first step for accurate
analysis. All subsequent gating steps are performed on these
compensated parameters, which are prefixed with "Comp-" in the
workspace file (e.g., `Comp-PE-A` instead of `PE-A`).

### Gating Strategy

The analysis follows a hierarchical gating strategy, where each
subsequent gate is applied to the population of cells selected by the
previous gate.

**Step 1: Isolate Lymphocytes by Size and Granularity**
*   **Gate Name:** `Lymphocytes`
*   **Parent Population:** All events
*   **Plot Parameters:** Forward Scatter Area (FSC-A) vs. Side Scatter Area (SSC-A)
*   **Purpose:** To create an initial gate around the population of cells that have the characteristic low side scatter (low granularity) and intermediate forward scatter (medium size) of lymphocytes, separating them from larger cells like macrophages and smaller debris.

**Step 2: Exclude Doublets (Singlet Gating)**

This is a two-step process to ensure that each analyzed event
corresponds to a single cell, not two or more cells stuck together
(doublets).

*   **Gate 2a:**
    *   **Gate Name:** `Single Cells`
    *   **Parent Population:** `Lymphocytes`
    *   **Plot Parameters:** Side Scatter Area (SSC-A) vs. Side Scatter Height (SSC-H)
    *   **Purpose:** To select cells that have a proportional relationship between their scatter area and height, as doublets will have a higher area for a given height.
*   **Gate 2b:**
    *   **Gate Name:** `Single Cells`
    *   **Parent Population:** Cells from Gate 2a.
    *   **Plot Parameters:** Forward Scatter Area (FSC-A) vs. Forward Scatter Height (FSC-H)
    *   **Purpose:** This is a second, more stringent doublet exclusion step, again selecting cells where FSC-A and FSC-H are linearly correlated.

**Step 3: Select Live Cells**
*   **Gate Name:** `Live cells`
*   **Parent Population:** `Single Cells` (from Gate 2b)
*   **Plot Parameters:** `Comp-PerCP-Cy5-5-A` (Live/Dead stain) vs. FSC-H
*   **Purpose:** To exclude dead cells. Dead cells have compromised membranes and can non-specifically bind antibodies, leading to false-positive signals. The gate is set on the `Live/Dead-negative` population.

**Step 4: Select T-Cells (CD3+)**
*   **Gate Name:** `CD3+`
*   **Parent Population:** `Live cells`
*   **Plot Parameters:** `Comp-APC-A` (CD3) vs. FSC-H
*   **Purpose:** To isolate the T-lymphocytes by gating on the cells that are positive for the CD3 marker, which is expressed on all T-cells.

**Step 5: Analyze CD4+ and CD8+ T-Cell Subsets**
*   **Parent Population:** `CD3+`
*   **Plot Parameters:** `Comp-BV786-A` (CD4) vs. `Comp-PE-A` (CD8)
*   **Purpose:** This is the final analysis step which generates the plots seen in **Figure 2B**. A quadrant gate is applied to the CD3+ population to separate it into four distinct subsets:
    *   **Upper-Left (Q1):** CD4+ / CD8- (Helper T-cells)
    *   **Upper-Right (Q2):** CD4+ / CD8+ (Double-positive cells, rare in periphery)
    *   **Lower-Right (Q3):** CD4- / CD8+ (Cytotoxic T-cells)
    *   **Lower-Left (Q4):** CD4- / CD8- (Double-negative T-cells)

This gating strategy is applied to all samples in the experiment
(Saline control, Anti-CD4 treated, Anti-CD8 treated, and Rag2-/-
negative control) to compare the percentages in each quadrant and thus
determine the efficacy of the T-cell depletion antibodies.

### Summary Table of the Gating Procedure

| Step | Gate Name      | Parent Population   | Parameters (Y-Axis vs. X-Axis)             | Purpose                                                  |
| :--- | :---           | :---                | :---                                       | :---                                                     |
|    0 | Compensation   | All events          | (Applied to all fluorescent channels)      | Correct for spectral overlap between fluorochromes.      |
|    1 | `Lymphocytes`  | All events          | SSC-A vs. FSC-A                            | Isolate lymphocytes based on size and granularity.       |
|   2a | `Single Cells` | `Lymphocytes`       | SSC-H vs. SSC-A                            | First step of doublet exclusion.                         |
|   2b | `Single Cells` | `Single Cells` (2a) | FSC-H vs. FSC-A                            | Second step of doublet exclusion.                        |
|    3 | `Live cells`   | `Single Cells` (2b) | FSC-H vs. `Comp-PerCP-Cy5-5-A` (Live/Dead) | Exclude dead cells to prevent non-specific staining.     |
|    4 | `CD3+`         | `Live cells`        | FSC-H vs. `Comp-APC-A` (CD3)               | Isolate all T-cells from the live singlet population.    |
|    5 | Quadrant Gate  | `CD3+`              | `Comp-BV786-A` (CD4) vs. `Comp-PE-A` (CD8) | Differentiate and quantify CD4+ and CD8+ T-cell subsets. |


## More Detailed description

Here is a detailed breakdown of the flow cytometry data processing,
including the spillover matrix estimation and values, exact gate
definitions, an explanation of parameter choices, and an overview of
the fluorochromes and their potential for crosstalk.

### **The Spillover Matrix: Estimation and Values**

The spillover matrix is not estimated from the experimental FCS files
themselves. Instead, it is determined through a dedicated
**calibration procedure** performed on the measurement device (the BD
FACSCelesta flow cytometer, Note: I see used ones on sale for 500USD
to 5000USD on EBay) *before* running the experimental samples.

#### **How the Matrix is Estimated:**

1.  **Single-Stain Controls:** The process requires a set of control samples, typically beads or cells, where each control is stained with only **one** of the fluorochrome-conjugated antibodies used in the full experimental panel (e.g., one tube with only anti-CD3-APC, one with only anti-CD4-BV786, etc.). An unstained control is also required to set the baseline fluorescence.
2.  **Data Acquisition:** Each single-stain control is run through the cytometer, and the fluorescence is measured in *all* detectors. For example, when the anti-CD3-APC sample is run, the machine measures the strong signal in the APC detector, but it also measures the weaker, "spillover" signal that this dye emits into other channels (like the APC-R700 channel).
3.  **Calculation:** The cytometer's acquisition software (in this case, BD FACSDiva, as indicated by the file metadata) uses this information to calculate the percentage of signal from a given fluorochrome that is incorrectly detected in another channel. This calculation generates the spillover matrix.
4.  **Application:** This calculated matrix is then saved as a setting. For this experiment, it was applied during data acquisition, meaning the compensation values are saved directly into the `.fcs` files. When the data is opened in an analysis software like FlowJo, it reads this "acquisition-defined" matrix and applies it to the data, creating the compensated parameters (e.g., `Comp-APC-A`) that are used for the actual analysis.

#### **Spillover Matrix Values from the Workspace File**

The exact spillover matrix used in this analysis is defined in the
`LST_Depletion_check_14-Feb-2022.wsp` file. The values represent the
percentage of spillover *from* the fluorochrome in the row *into* the
fluorochrome in the column.

| Spilling FROM ↓ | INTO: BV421 | INTO: BV510 | INTO: BV605 | INTO: BV650 | INTO: BV786 | INTO: BB515 | INTO: PE | INTO: PE-CF594 | INTO: PerCP-Cy5.5 | INTO: APC | INTO: APC-R700 | INTO: APC-Cy7 |
| :---            |        :--- |        :--- |        :--- |        :--- |        :--- |        :--- |     :--- |           :--- |              :--- |      :--- |           :--- |          :--- |
| **BV421**       |        100% |      15.52% |       0.71% |       0.16% |       0.01% |       0.00% |    0.00% |          0.00% |             0.00% |     0.00% |          0.00% |         0.00% |
| **BV510**       |       6.93% |        100% |      31.64% |      15.63% |       1.70% |       0.13% |    0.10% |          0.05% |             0.04% |     0.00% |          0.00% |         0.02% |
| **BV605**       |       1.99% |       0.00% |        100% |      65.67% |       6.33% |       0.02% |    0.62% |          1.82% |             0.70% |     0.31% |          0.01% |         0.00% |
| **BV650**       |       0.00% |       0.00% |       0.00% |        100% |       0.00% |       0.00% |    0.00% |          0.00% |             0.00% |     0.00% |          0.00% |         0.00% |
| **BV786**       |       2.87% |       0.56% |       0.09% |       0.29% |        100% |       0.00% |    0.00% |          0.00% |             0.00% |     0.04% |          0.31% |         3.76% |
| **BB515**       |       0.00% |      12.34% |       1.43% |       0.40% |       0.00% |        100% |   32.70% |          7.75% |             1.43% |     0.00% |          0.00% |         0.00% |
| **PE**          |       0.01% |       0.61% |      14.15% |       4.27% |       0.28% |       0.74% |     100% |         29.92% |             6.54% |     0.00% |          0.01% |         0.00% |
| **PE-CF594**    |       0.03% |       0.12% |      40.62% |      21.27% |       1.62% |       0.17% |   15.86% |           100% |            34.57% |     0.55% |          0.08% |         0.00% |
| **PerCP-Cy5.5** |       0.00% |       0.00% |      19.53% |     102.76% |      16.65% |       0.00% |    2.80% |         25.82% |              100% |    15.85% |          4.59% |         1.73% |
| **APC**         |       0.00% |       0.00% |       0.00% |       8.01% |       0.60% |       0.00% |    0.00% |          0.00% |             0.20% |      100% |         14.87% |         5.43% |
| **APC-R700**    |       0.00% |       0.00% |       0.00% |       2.23% |       2.92% |       0.00% |    0.00% |          0.00% |             0.85% |    39.59% |           100% |        29.13% |
| **APC-Cy7**     |       0.02% |       0.07% |       0.00% |       0.55% |      12.38% |       0.02% |    0.01% |          0.02% |             0.00% |     6.37% |          6.94% |          100% |

### **Gate Definitions and Computations**

Below are the exact definitions of the gates used in the hierarchical
analysis, extracted directly from the `.wsp` file. The computation is
a geometric test: for an event to be included in a sub-population, its
parameter values must fall within the boundaries of the defined
polygon or rectangle.

**Step 1: Lymphocytes Gate**
*   **Gate Type:** Polygon
*   **Parent Population:** All events
*   **Parameters:** SSC-A vs. FSC-A
*   **Definition (Vertices):**
    ```
    (FSC-A, SSC-A)
    (71593.9, 37622.5), (73796.8, 31554.4), (78202.6, 27913.5), (82608.4, 25486.2),
    (90318.5, 25486.2), (94724.3, 29127.1), (99130.1, 31554.4), (104637.3, 36408.9),
    (107941.6, 40049.8), (111246.0, 44904.3), (113448.9, 49758.8), (115651.8, 55827.0),
    (115651.8, 63108.7), (111246.0, 69176.9), (107941.6, 71604.1), (101333.0, 75245.0),
    (96927.2, 77672.3), (89217.1, 77672.3), (84811.3, 72817.8), (82608.4, 67963.3),
    (80405.5, 61895.1), (79304.1, 55827.0), (75999.7, 49758.8), (72695.4, 43690.7)
    ```

**Step 2a & 2b: Single Cells Gates (Doublet Exclusion)**
*   **Gate 2a: Single Cells**
    *   **Gate Type:** Polygon
    *   **Parent Population:** `Lymphocytes`
    *   **Parameters:** SSC-H vs. SSC-A
    *   **Definition (Vertices):**
        ```
        (SSC-A, SSC-H)
        (20927.5, 30340.7), (28637.6, 25486.2), (95825.7, 91022.2), (94724.3, 109226.7)
        ```
*   **Gate 2b: Single Cells**
    *   **Gate Type:** Polygon
    *   **Parent Population:** `Single Cells` (from Gate 2a)
    *   **Parameters:** FSC-H vs. FSC-A
    *   **Definition (Vertices):**
        ```
        (FSC-A, FSC-H)
        (63883.8, 69176.9), (72695.4, 66749.6), (123361.9, 117722.1), (122260.4, 134712.9)
        ```

**Step 3: Live Cells Gate**
*   **Gate Type:** Rectangle
*   **Parent Population:** `Single Cells` (from Gate 2b)
*   **Parameters:** `Comp-PerCP-Cy5-5-A` (Live/Dead), FSC-H
*   **Definition (Thresholds):**
    *   `Comp-PerCP-Cy5-5-A`: min = -323.58, max = 543.07
    *   `FSC-H`: min = 16990.81, max = 241512.30

**Step 4: CD3+ T-Cells Gate**
*   **Gate Type:** Rectangle
*   **Parent Population:** `Live cells`
*   **Parameters:** `Comp-APC-A` (CD3), FSC-H
*   **Definition (Thresholds):**
    *   `Comp-APC-A`: min = 1801.68, max = 132607.86
    *   `FSC-H`: min = 41263.41, max = 146849.19

**Step 5: CD4/CD8 Quadrant Gate**
*   **Gate Type:** Quadrant (defined by intersection of two rectangular gates)
*   **Parent Population:** `CD3+`
*   **Parameters:** `Comp-BV786-A` (CD4), `Comp-PE-A` (CD8)
*   **Definition (Thresholds):**
    *   Vertical line (dividing CD8- and CD8+): `Comp-PE-A` = 638.66
    *   Horizontal line (dividing CD4- and CD4+): `Comp-BV786-A` = 1846.06

### **The Role of FSC-H in Gating**

You correctly identified that FSC-H is used for doublet exclusion. Its
appearance on the Y-axis for the **Live/Dead** and **CD3** gates
serves a different but important purpose: **visualization and clear
separation**.

When you want to make a gating decision based on a single fluorescent marker (like the Live/Dead stain or CD3), you have two options:
1.  **1D Histogram:** Plot the intensity of the marker on a single axis. This shows positive and negative peaks, but if they are not well-separated, it can be difficult to decide exactly where to place the gate.
2.  **2D Dot Plot:** Plot the marker of interest on the X-axis against another parameter on the Y-axis. This spreads the data into two dimensions.

FSC-H (Forward Scatter - Height) is an excellent choice for the Y-axis
in this context because it is a non-fluorescent, physical parameter of
the cell. Using it helps to visually "stretch" the cell cloud
vertically, making the distinction between the negative and positive
populations on the X-axis much clearer. This allows the researcher to
draw a more confident and accurate rectangular gate around the
population of interest (e.g., all `Live/Dead-negative` cells or all
`CD3-positive` cells) without the Y-axis parameter influencing the
selection based on fluorescence.

### **Excitation Wavelengths, Fluorochromes, and Crosstalk Overview**

The BD FACSCelesta cytometer used in this study was configured with
three lasers: Violet (405 nm), Blue (488 nm), and Red (640 nm).

| Decision Step | Gating Parameters | Fluorescence Used? | Excitation Laser (Wavelength) | Fluorochrome(s) & Marker(s) | Key Crosstalk Issues / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1. Lymphocytes | FSC-A vs. SSC-A | No | N/A | N/A | Based on physical properties (size/granularity). |
| 2. Single Cells | FSC-A/H, SSC-A/H | No | N/A | N/A | Based on physical properties (pulse shape). |
| 3. Live Cells | `Comp-PerCP-Cy5.5` | Yes | Blue (488 nm) | PerCP-Cy5.5 (Live/Dead stain) | **Tandem Dye.** PerCP has significant spillover into BV650, BV786, and APC, making compensation critical. |
| 4. CD3+ T-Cells | `Comp-APC-A` | Yes | Red (640 nm) | APC (CD3) | APC spills significantly into the APC-R700 detector (14.87%) and has minor spillover into APC-Cy7 (5.43%). |
| 5. CD4/CD8 | `Comp-BV786-A` & `Comp-PE-A` | Yes | Violet (405 nm) & Blue (488 nm) | BV786 (CD4), PE (CD8) | **BV786:** Spills into APC-R700 (0.31%) and APC-Cy7 (3.76%). **PE:** Spills significantly into PE-CF594 (29.92%) and BV605 (14.15%). |

**Tandem Dyes and Crosstalk:**

This panel heavily relies on **tandem dyes**, specifically
**PerCP-Cy5.5** and **APC-R700**.

*   **How they work:** Tandem dyes consist of two covalently linked fluorochromes. The "donor" molecule (e.g., PE or APC) absorbs energy from the laser and transfers it to an "acceptor" molecule (e.g., CF594 or the R700 dye) through a process called Förster Resonance Energy Transfer (FRET). The acceptor then emits light at a longer wavelength than the donor would have. This allows a single laser to excite multiple dyes that emit at very different wavelengths, greatly expanding the number of markers that can be analyzed simultaneously.
*   **Crosstalk Implication:** The complexity of tandem dyes makes accurate compensation essential. Any degradation of the acceptor dye can "uncouple" the tandem, causing the donor molecule to fluoresce at its original wavelength. This leads to unexpected and incorrect signals in other detectors, which can only be corrected with a robust, freshly prepared set of single-stain compensation controls. As seen in the matrix, there is significant crosstalk between dyes excited by the same laser (e.g., the Brilliant Violets) and even between dyes on different lasers due to their broad emission spectra.
