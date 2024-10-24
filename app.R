library(shiny)
library(dplyr)
library(readxl)
library(ggplot2)
library(plotly)
library(shinythemes)
library(shinycssloaders)
library(leaflet)
library(openxlsx)

# Load the postcode data
postcode_data <- read.csv("au_postcodes.csv") %>%
  select(Postcode = postcode, Latitude = latitude, Longitude = longitude, Suburb = place_name, State = state_name) %>%
  distinct()

# Helper functions
calculate_growth_rate <- function(y2, y1, years) {
  ((y2 / y1) ^ (1 / years)) - 1
}

calculate_dwellings_forwards <- function(avg, prev_date, years) {
  prev_date * (1 + avg) ^ years
}

# Load the dwelling data
load_dwellings_data <- function() {
  list(
    total_dwellings = read_excel("dwellings_backwards_estimated.xlsx", sheet = "Total Dwellings"),
    detached_dwellings = read_excel("dwellings_backwards_estimated.xlsx", sheet = "Detached Dwellings")
  )
}

available_years <- names(load_dwellings_data()$total_dwellings)[-1]  # Remove 'Postcode' column
available_postcodes <- unique(load_dwellings_data()$total_dwellings$Postcode)




# Define UI for the application
ui <- navbarPage(
  theme = shinytheme("cosmo"), 
  title = "Renovation Demand Forecast",
  
  # Tab 1: Original Results and Forecast
  tabPanel(
    title = "Results",
    sidebarLayout(
      sidebarPanel(
        selectizeInput("postcode", label = h4("Search and Select Postcodes:", style = "color: #16a085;"),
                       choices = unique(postcode_data$Postcode), multiple = TRUE,
                       options = list(placeholder = 'Type to search postcodes')),
        selectInput("project", label = h4("Select Project Type:", style = "color: #16a085;"), choices = c("Bathroom Main", "Kitchen")),
        sliderInput("year_range", label = h4("Select Year Range:", style = "color: #16a085;"), min = 2022, max = 2031, value = c(2022, 2026)),
        selectInput("plot_type", label = h4("Select Plot Type:", style = "color: #16a085;"), choices = c("Line Plot" = "line", "Bar Plot" = "bar")),
        actionButton("calculate", label = "Calculate Renovation Demand", class = "btn btn-success", style = "background-color: #1abc9c; color: white;"),
        br(), br(),
        downloadButton("downloadData", "Download as CSV", class = "btn btn-primary", style = "background-color: #1abc9c; color: white;"),
        br(), br(),
        downloadButton("downloadExcel", "Download as Excel", class = "btn btn-primary", style = "background-color: #1abc9c; color: white;")
      ),
      mainPanel(
        tabsetPanel(
          tabPanel("Results", h3("Renovation Demand Forecast by Postcode", style = "color: #2980b9; text-align: center;"), uiOutput("tables_by_postcode") %>% withSpinner(color="#1abc9c")),
          tabPanel("Plots", h3("Renovation Demand Comparison Across Postcodes", style = "color: #2980b9; text-align: center;"), plotlyOutput("renovation_plot") %>% withSpinner(color="#1abc9c")),
          tabPanel("Suburbs", h3("Suburbs in Selected Postcodes", style = "color: #2980b9; text-align: center;"), uiOutput("suburb_table") %>% withSpinner(color="#1abc9c")),
          tabPanel("Map", h3("Map of Selected Postcodes", style = "color: #2980b9; text-align: center;"), leafletOutput("postcode_map", height = 600) %>% withSpinner(color="#1abc9c"))
        )
      )
    )
  ),
  
  # Tab 2: Custom Estimation Feature with Separate Sidebar
  tabPanel(
    title = "Calculator",
    sidebarLayout(
      sidebarPanel(
        h3("Select Parameters", style = "color: #16a085;"),
        p("Use the options below to calculate the growth rate and forecast for a target year."),
        
        selectInput("dwelling_type", "Select Dwelling Type", 
                    choices = c("Total Dwellings", "Detached Dwellings"), 
                    selected = "Total Dwellings"),
        
        selectInput("postcode", "Select Postcode", choices = available_postcodes),
        selectInput("start_year", "Select Start Year", choices = available_years),
        selectInput("end_year", "Select End Year", choices = available_years),
        
        
        numericInput("calc_year", "Enter Target Year", value = 2030),
        helpText("This is the year for which the forecast will be calculated."),
        
        actionButton("run_calculation", "Run Calculation", class = "btn btn-primary btn-lg", style = "background-color: #1abc9c; color: white;"),
        br(), br(),
        p("After selecting your parameters, click 'Run Calculation' to see the results.")
      ),
      mainPanel(
        h3("Results", style = "color: #2980b9; text-align: center;"),
        br(),
        
        h4("1. Growth Rate Calculation", style = "color: #16a085;"),
        p("The growth rate is calculated between the selected start and end years."),
        tableOutput("growth_rate_result"),
        br(),
        
        h4("2. Dwelling Forecast for Target Year", style = "color: #16a085;"),
        p("The dwelling count for the target year is estimated using the calculated growth rate."),
        tableOutput("dwelling_forecast"),
        br(),
        
        h4("Download Results", style = "color: #16a085;"),
        downloadButton("download_result", "Download as Excel", class = "btn btn-primary", style = "background-color: #1abc9c; color: white; width: 100%; margin-top: 10px;")
      )
    )
  ),
  
  # Tab 3: Custom Growth Rate Feature
  tabPanel(
    title = "Custom",
    sidebarLayout(
      sidebarPanel(
        h3("Input Parameters", style = "color: #16a085;"),
        actionButton("add_pair", "Add Year-Value Pair", class = "btn btn-primary", style = "background-color: #1abc9c; color: white;"),
        actionButton("remove_pair", "Remove Last Pair", class = "btn btn-primary", style = "background-color: #1abc9c; color: white;"),
        br(), br(),
        uiOutput("dynamic_inputs"),
        numericInput("target_year", label = HTML("<span style='color: #16a085;'>Enter Target Year</span>"), value = 1980),
        actionButton("calculate_growth", "Calculate Growth", class = "btn btn-primary", style = "background-color: #1abc9c; color: white;"),
        br(),
        checkboxInput(
          inputId = "use_custom_growth_rate",
          label = HTML("<span style='color: #16a085;'>Use Custom Growth Rate?</span>"),
          value = FALSE
        ),
        
        # Numeric input for the custom growth rate (only shown if the checkbox is selected)
        conditionalPanel(
          condition = "input.use_custom_growth_rate == true",
          numericInput(
            inputId = "custom_growth_rate",
            label = HTML("<span style='color: #16a085;'>Enter Custom Growth Rate (% per year)</span>"),
            value = 5  # Default growth rate as percentage
          )
        ),
        p("Click 'Calculate Growth' to compute the growth rates and forecast the target year value.")
      ),
      mainPanel(
        h3("Results", style = "color: #2980b9; text-align: center;"),
        br(),
        h4("Growth Rate Formula", style = "color: #16a085;"),
        HTML("<p><strong>g</strong> = (V<sub>end</sub> / V<sub>start</sub>)<sup>1 / (Y<sub>end</sub> - Y<sub>start</sub>)</sup> - 1</p>"),
        h4("Target Year Value Formula", style = "color: #16a085;"),
        HTML("<p><strong>V<sub>target</sub></strong> = V<sub>last</sub> &times; (1 + g)<sup>(Y<sub>target</sub> - Y<sub>last</sub>)</sup></p>"),
        br(),
        tableOutput("growth_rate_table"),
        br(),
        h4("Description", style = "color: #16a085;"),
        textOutput("growth_rate_used"),
        br(),
        textOutput("target_value_result"),
        br(), br(),
        plotlyOutput("growth_plot") %>% withSpinner(color="#1abc9c")
      )
    )
  )
)

# Server logic
server <- function(input, output) {
  file_path <- "Renovation forecast model V21 (23-06-24).xlsx"
  
  # Reactive expression to process the data based on user input
  forecast_data <- eventReactive(input$calculate, {
    # Read the total dwellings data
    data <- read_excel(file_path, sheet = "Data", range = "Data!B21:AD34")
    
    # Get the selected postcodes
    selected_postcodes <- toupper(input$postcode)
    
    # Loop over the selected postcodes to calculate the forecast for each
    results <- lapply(selected_postcodes, function(postcode) {
      if (postcode %in% data$`Detached Dwellings`) {
        # Extract the years and dwellings based on the input postcode
        year <- as.numeric(names(data)[-2])
        year <- year[!is.na(year)]  # Remove NA values
        total_dwellings <- as.numeric(data[data$`Detached Dwellings` == postcode, ][-c(1, 2)])
        
        # Ensure numeric values
        if (any(is.na(total_dwellings))) {
          showNotification(paste("Data for postcode", postcode, "contains non-numeric values."), type = "error")
          return(NULL)
        }
        
        # Read the product life data
        product_life_data <- read_excel(file_path, range = "Master!D507:EC508")
        product_life_data['131'] <- c(30)
        product_life <- as.numeric(product_life_data)
        
        # Read the uptake data
        uptake_data <- read_excel(file_path, col_names = FALSE, range = "Master!D771:EC771")
        uptake_data['X_new'] <- 1
        uptake_rate <- as.numeric(uptake_data)
        
        # Interpolate the total dwellings data
        postcodes_data <- data.frame(year, total_dwellings)
        all_years <- seq(min(postcodes_data$year), max(postcodes_data$year))
        interpolated_dwellings <- approx(postcodes_data$year, postcodes_data$total_dwellings, xout = all_years)$y
        
        interpolated_df <- data.frame(year = all_years, total_dwellings = interpolated_dwellings)
        interpolated_df$product_life <- product_life[1:nrow(interpolated_df)]
        interpolated_df$uptake_rate <- uptake_rate[1:length(all_years)]
        
        interpolated_df <- interpolated_df %>% 
          mutate(renovation_index = match(year - product_life, year)) %>%
          mutate(increase = c(diff(total_dwellings), 0)) %>%
          mutate(renovation = ifelse(!is.na(renovation_index), increase[renovation_index], 0)) %>%
          select(-renovation_index)
        
        # Filter for post-1961 data and year range
        filtered_df <- interpolated_df %>% filter(year >= 1961) %>%
          filter(year >= input$year_range[1] & year <= input$year_range[2])
        
        # Calculate the renovation demand for selected years and postcodes
        renovation_df <- filtered_df %>%
          group_by(year) %>%
          summarise(post_1961_additions = sum(increase * uptake_rate * 1000, na.rm = TRUE)) %>%
          arrange(year)
        
        # Add a column for the postcode
        renovation_df <- renovation_df %>% mutate(Postcode = postcode)
        renovation_df <- renovation_df %>%
          rename(
            "Year" = year,
            "Post 1961 Additions" = post_1961_additions,
            "Postcode" = Postcode
          )
        
        # Return the filtered data frame
        renovation_df
      } else {
        data.frame(Message = paste("Postcode", postcode, "not found in data"), Postcode = postcode)
      }
    })
    
    # Combine the results for all postcodes
    do.call(rbind, results)
  })
  
  # Render renovation forecast tables for each postcode (results tab)
  output$tables_by_postcode <- renderUI({
    data <- forecast_data()
    if (is.null(data) || nrow(data) == 0 || !"Postcode" %in% colnames(data)) return()
    lapply(unique(data$Postcode), function(postcode) {
      filtered_data <- data %>% filter(Postcode == postcode)
      tagList(h4(paste("Renovation Demand for Postcode", postcode), style = "color: #16a085;"), tableOutput(paste0("table_", postcode)))
    })
  })
  
  observe({
    data <- forecast_data()
    if (is.null(data) || nrow(data) == 0 || !"Postcode" %in% colnames(data)) return()
    lapply(unique(data$Postcode), function(postcode) {
      filtered_data <- data %>% filter(Postcode == postcode)
      output[[paste0("table_", postcode)]] <- renderTable({filtered_data})
    })
  })
  
  # Render the suburb table based on selected postcodes
  output$suburb_table <- renderUI({
    req(input$postcode)
    selected_suburbs <- postcode_data %>% filter(Postcode %in% input$postcode)
    if (nrow(selected_suburbs) > 0) {
      tagList(tableOutput("suburb_list"))
    } else {
      p("No suburbs available for the selected postcodes.")
    }
  })
  
  output$suburb_list <- renderTable({
    postcode_data %>% filter(Postcode %in% input$postcode) %>% select(Postcode, Suburb, State)
  })
  
  # Render the renovation plot
  output$renovation_plot <- renderPlotly({
    data <- forecast_data()
    if (is.null(data) || nrow(data) == 0 || !"Postcode" %in% colnames(data)) return()
    p <- ggplot(data, aes(x = Year, y = `Post 1961 Additions`, color = Postcode, group = Postcode)) +
      {
        if (input$plot_type == "line") {
          geom_line(size = 1)
        } else {
          geom_bar(stat = "identity", position = "dodge", width = 0.8)
        }
      } +
      labs(title = "Renovation Demand by Year", x = "Year", y = "Renovation Demand") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Render the map based on selected postcodes
  output$postcode_map <- renderLeaflet({
    req(input$postcode)
    selected_data <- postcode_data %>% filter(Postcode %in% input$postcode)
    leaflet() %>%
      addTiles() %>%
      setView(lng = mean(selected_data$Longitude), lat = mean(selected_data$Latitude), zoom = 10) %>%
      addCircleMarkers(lng = selected_data$Longitude, lat = selected_data$Latitude,
                       popup = selected_data$Postcode,
                       radius = 8, color = "#0073B7", fillOpacity = 0.7)
  })
  
  # Download handlers
  output$downloadData <- downloadHandler(
    filename = function() { paste("renovation-forecast-", Sys.Date(), ".csv", sep="") },
    content = function(file) {
      write.csv(forecast_data(), file, row.names = FALSE)
    }
  )
  
  output$downloadExcel <- downloadHandler(
    filename = function() { paste("renovation-forecast-", Sys.Date(), ".xlsx", sep="") },
    content = function(file) {
      write.xlsx(forecast_data(), file)
    }
  )
  
  # Calculator tab logic
  selected_data <- reactive({
    if (input$dwelling_type == "Total Dwellings") {
      return(load_dwellings_data()$total_dwellings)
    } else {
      return(load_dwellings_data()$detached_dwellings)
    }
  })
  
  # Reactive function to calculate growth rate and forecast
  growth_rate_result <- eventReactive(input$run_calculation, {
    # Get the selected postcode and year columns from the selected dataset
    data <- selected_data() %>% filter(Postcode %in% input$postcode)
    start_year <- as.numeric(input$start_year)
    end_year <- as.numeric(input$end_year)
    
    # Extract the values for the selected years
    y1 <- as.numeric(data[[input$start_year]])
    y2 <- as.numeric(data[[input$end_year]])
    
    # Calculate the number of years between the start and end year
    years_interval <- end_year - start_year
    
    # Calculate growth rate
    growth_rate <- calculate_growth_rate(y2, y1, years_interval)
    
    # Calculate years from start year to target year
    calc_year <- input$calc_year
    years_to_calc <- calc_year - end_year
    
    # Calculate dwellings for the target year
    dwellings_target_year <- calculate_dwellings_forwards(growth_rate, y2, years_to_calc)
    
    # Generate interpolated data for the plot
    year_sequence <- seq(start_year, end_year, by = 1)
    interpolated_dwellings <- y1 * (1 + growth_rate) ^ (year_sequence - start_year)
    
    list(
      growth_rate = growth_rate,
      dwellings_target_year = dwellings_target_year,
      year_sequence = year_sequence,
      interpolated_dwellings = interpolated_dwellings
    )
  })
  
  # Output the growth rate result as a table
  output$growth_rate_result <- renderTable({
    result <- growth_rate_result()
    if (is.null(result)) return()
    data.frame(
      "Growth Rate (from Start to End Year)" = result$growth_rate,
      check.names = FALSE
    )
  })
  
  # Output the dwelling forecast result as a table
  output$dwelling_forecast <- renderTable({
    result <- growth_rate_result()
    if (is.null(result)) return()
    data.frame(
      "Estimated Dwellings in Target Year" = result$dwellings_target_year,
      check.names = FALSE
    )
  })
  
  # Allow users to download the results as an Excel file
  output$download_result <- downloadHandler(
    filename = function() {
      paste("dwelling_forecast_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      result <- growth_rate_result()
      if (is.null(result)) return()
      df <- data.frame(
        "Growth Rate (from Start to End Year)" = result$growth_rate,
        "Estimated Dwellings in Target Year" = result$dwellings_target_year,
        check.names = FALSE
      )
      writexl::write_xlsx(df, path = file)
    }
  )
  
  
  # Custom tab logic
  rv <- reactiveValues(num_pairs = 2)
  
  observeEvent(input$add_pair, {
    rv$num_pairs <- rv$num_pairs + 1
  })
  
  observeEvent(input$remove_pair, {
    if (rv$num_pairs > 2) {
      rv$num_pairs <- rv$num_pairs - 1
    }
  })
  
  output$dynamic_inputs <- renderUI({
    lapply(1:rv$num_pairs, function(i) {
      tagList(
        numericInput(paste0("year", i), label = HTML(paste("<span style='color: #16a085;'>Year", i, "</span>")), value = 1990 + (i - 1) * 5),
        numericInput(paste0("value", i), label = HTML(paste("<span style='color: #16a085;'>Dwelling Value in Year", i, "</span>")), value = 800 + (i - 1) * 100)
      )
    })
  })
  
  observeEvent(input$calculate_growth, {
    years <- sapply(1:rv$num_pairs, function(i) as.numeric(input[[paste0("year", i)]]))
    values <- sapply(1:rv$num_pairs, function(i) as.numeric(input[[paste0("value", i)]]))
    if (any(diff(years) <= 0) || any(values <= 0)) {
      showNotification("Years must be in increasing order and dwelling values must be positive numbers!", type = "error")
      return()
    }
    growth_rates <- sapply(2:rv$num_pairs, function(i) ((values[i] / values[i-1]) ^ (1 / (years[i] - years[i-1]))) - 1)
    growth_rate_last <- if (input$use_custom_growth_rate) {
      input$custom_growth_rate / 100
    } else {
      growth_rates[length(growth_rates)]
    }
    last_value <- values[1]
    last_year <- years[1]
    target_value <- last_value * (1 + growth_rate_last) ^ (input$target_year - last_year)
    growth_rate_data <- data.frame("Start Year" = as.integer(years[-length(years)]), "End Year" = as.integer(years[-1]), "Growth Rate (%)" = round(growth_rates * 100, 2))
    colnames(growth_rate_data) <- c("Start Year", "End Year", "Growth Rate (%)")
    output$growth_rate_table <- renderTable({growth_rate_data})
    output$growth_rate_used <- renderText({
      if (input$use_custom_growth_rate) {
        paste("Custom Growth Rate Used: ", round(input$custom_growth_rate, 2), "% per year.")
      } else {
        paste("Growth Rate Used: From Year", last_year, "to Year", input$target_year, "=", round(growth_rate_last * 100, 2), "% per year.")
      }
    })
    output$target_value_result <- renderText({paste("Estimated Dwelling Value in Year", input$target_year, "=", round(target_value))})
    output$growth_plot <- renderPlotly({
      plot_data <- data.frame(Year = c(years, input$target_year), Dwelling_Value = c(values, target_value))
      p <- ggplot(plot_data, aes(x = Year, y = Dwelling_Value)) + geom_line(color = "#2c7bb6") + geom_point(size = 3, color = "#2c7bb6") + ggtitle("Dwelling Growth Over Time") + xlab("Year") + ylab("Dwelling Value") + theme_minimal()
      ggplotly(p, tooltip = c("x", "y"))
    })
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
