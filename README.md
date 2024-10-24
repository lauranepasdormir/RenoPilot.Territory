# RenoPilot.Territory
## Overview

This is a Shiny-based web application called **Territory App**, designed as part of the RenoPilot ecosystem. The application provides data-driven insights to help renovation contractors and service providers make informed decisions. It integrates various data sources, including historical dwelling records, to predict renovation demand for different areas, specifically tailored for the Australian market.

The app consists of multiple interactive features, including forecast visualization, a growth rate calculator, and customizable prediction tools to help contractors optimize their marketing and resource allocation strategies.

## Features

### 1. Results Tab
- **Search and Select Postcodes**: Users can select multiple postcodes to visualize renovation demand.
- **Select Project Type**: Choose from renovation types like "Bathroom Main" or "Kitchen."
- **Select Year Range**: View demand forecasts for a specific time frame.
- **Plot Visualization**: Compare renovation demands across multiple postcodes using line or bar plots.
- **Download Options**: Users can download the generated forecast data in CSV or Excel formats.
- **Suburb Information**: View suburbs related to selected postcodes.
- **Interactive Map**: Display selected postcodes on a map for better geographic visualization.

### 2. Calculator Tab
- **Dwelling Type and Postcode Selection**: Users can choose dwelling types and postcodes for growth rate calculation.
- **Start, End, and Target Year Selection**: Calculate growth rates and predict demand for the target year based on historical data.
- **Interactive Calculations**: Generate growth rate tables and forecasts.
- **Download Results**: Users can download the calculation results in Excel format.

### 3. Custom Tab
- **Year-Value Pair Input**: Add and remove custom year-value pairs to define renovation trends.
- **Custom Growth Rate**: Option to provide a custom growth rate for forecasting.
- **Dynamic Results**: Visualize the calculated growth rates and forecast value for a target year.
- **Interactive Graphs**: Use Plotly to provide interactive visualizations of the forecast trends.

## Installation and Setup

### Prerequisites
- R version 4.0 or higher.
- RStudio (optional but recommended).
- Required R packages:
  - `shiny`
  - `dplyr`
  - `readxl`
  - `ggplot2`
  - `plotly`
  - `shinythemes`
  - `shinycssloaders`
  - `leaflet`
  - `openxlsx`

### Steps to Install and Run
1. Clone the repository or download the source code.
2. Make sure the necessary data files (`au_postcodes.csv` and `dwellings_backwards_estimated.xlsx`) are available in the root folder.
3. Open `app.R` or equivalent script in RStudio.
4. Install required packages using the command:
   ```R
   install.packages(c("shiny", "dplyr", "readxl", "ggplot2", "plotly", "shinythemes", "shinycssloaders", "leaflet", "openxlsx"))
   ```
5. Run the app by clicking "Run App" in RStudio or by executing the following command in R:
   ```R
   runApp("path/to/RenoPilot.Territory")
   ```
   If you would like to run it in vscode, execute the following command within the dirctionary:
   ```
   rscript app.r
   ```
6. The app will open in your default web browser.

## Structure
- **au_postcodes.csv**: Contains Australian postcode data, including latitude, longitude, suburb, and state information.
- **dwellings_backwards_estimated.xlsx**: Contains historical data related to dwellings and renovations.
- **app.R**: Main script containing the Shiny app UI and server logic.

## Usage
The app is intended for contractors, service providers, and homeowners looking to understand renovation trends and predict renovation demands. Users can select specific areas, view data trends, and even set their custom parameters to generate personalized forecasts.

## Important Notes
- The app requires Excel files and CSV data to work properly. Ensure these files are kept in the specified path.
- If certain postcodes are not found, the app will display a message notifying users that the selected postcode is not available in the data.
- Custom growth rate inputs allow more flexibility, enabling users to override default calculations when needed.

## Known Issues
- **Loading Delay**: Depending on the dataset size, there may be a delay in loading data and generating forecasts.
- **Data Availability**: The accuracy of predictions is directly related to the accuracy of input data. Users should verify the data sources before use.


## Acknowledgments
- **RenoPilot Team** for providing domain knowledge and guidance.
- **R Community** for resources related to Shiny app development.

