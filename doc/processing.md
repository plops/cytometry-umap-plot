Based `.fcs` column names ('FSC-A', 'FSC-H', 'FSC-W', 'SSC-A', 'SSC-H', 'SSC-W', 'BV421-A', 'BV510-A', 'BV605-A', 'BV650-A', 'CD4', 'BB515-A', 'CD8', 'PE-CF594-A', 'Live/Dead', 'CD3', 'APC-R700-A', 'CD45', the paper's Figure 2, and the detailed `LST_Depletion_check_14-Feb-2022.wsp` FlowJo workspace file, here is the step-by-step procedure for processing the flow cytometry data to generate the dot plots shown in Figure 2B.

The overall goal is to isolate the population of single, live T-cells (CD3+) from splenocytes and then analyze the presence of CD4+ and CD8+ subsets within that population to check the antibody depletion efficacy.

### Initial Processing: Compensation

Before any gating, the raw data from the `.fcs` files must be compensated. The `.wsp` file contains an acquisition-defined **spillover matrix** that corrects for the spectral overlap between different fluorochromes. This is a crucial first step for accurate analysis. All subsequent gating steps are performed on these compensated parameters, which are prefixed with "Comp-" in the workspace file (e.g., `Comp-PE-A` instead of `PE-A`).

### Gating Strategy

The analysis follows a hierarchical gating strategy, where each subsequent gate is applied to the population of cells selected by the previous gate.

**Step 1: Isolate Lymphocytes by Size and Granularity**
*   **Gate Name:** `Lymphocytes`
*   **Parent Population:** All events
*   **Plot Parameters:** Forward Scatter Area (FSC-A) vs. Side Scatter Area (SSC-A)
*   **Purpose:** To create an initial gate around the population of cells that have the characteristic low side scatter (low granularity) and intermediate forward scatter (medium size) of lymphocytes, separating them from larger cells like macrophages and smaller debris.

**Step 2: Exclude Doublets (Singlet Gating)**
This is a two-step process to ensure that each analyzed event corresponds to a single cell, not two or more cells stuck together (doublets).
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

This gating strategy is applied to all samples in the experiment (Saline control, Anti-CD4 treated, Anti-CD8 treated, and Rag2-/- negative control) to compare the percentages in each quadrant and thus determine the efficacy of the T-cell depletion antibodies.

### Summary Table of the Gating Procedure

| Step | Gate Name | Parent Population | Parameters (Y-Axis vs. X-Axis) | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| 0 | Compensation | All events | (Applied to all fluorescent channels) | Correct for spectral overlap between fluorochromes. |
| 1 | `Lymphocytes` | All events | SSC-A vs. FSC-A | Isolate lymphocytes based on size and granularity. |
| 2a | `Single Cells` | `Lymphocytes` | SSC-H vs. SSC-A | First step of doublet exclusion. |
| 2b | `Single Cells` | `Single Cells` (2a) | FSC-H vs. FSC-A | Second step of doublet exclusion. |
| 3 | `Live cells` | `Single Cells` (2b) | FSC-H vs. `Comp-PerCP-Cy5-5-A` (Live/Dead) | Exclude dead cells to prevent non-specific staining. |
| 4 | `CD3+` | `Live cells` | FSC-H vs. `Comp-APC-A` (CD3) | Isolate all T-cells from the live singlet population. |
| 5 | Quadrant Gate | `CD3+` | `Comp-BV786-A` (CD4) vs. `Comp-PE-A` (CD8) | Differentiate and quantify CD4+ and CD8+ T-cell subsets. |