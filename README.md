# Line analysis 2.0
This line analysis workflow is designed to extract raster data at fixed intervals along lines to generate line level summary metrics. It was developed for wildland fire management to rate potential containment lines on multiple dimensions of opportunity, difficulty, and safety. The core sampling, extraction, and summary workflow may have other applications in natural resources management.

**Major changes from earlier versions**

1) The spatial input is simplified to a single polyline shapefile. The shapefile must have a spatial projection defined. Features should be singlepart; if not, they will be converted to singlepart in the script. Instead of representing multiple strategies in different shapefiles, users are encouraged to attribute their lines with a “Strategy” text attribute field using P-A-C-E terms, Direct/Indirect, or similar classification scheme.
2) Raster inputs can now have different extents, cell sizes, cell alignments, and projections.
3) Raster inputs are loaded one at a time to reduce the memory limitation errors.
4) There is now an optional workflow for creating barplots to contrast strategies if lines are attributed with a text “Strategy” field.

**Sampling framework**

The sampling scheme was designed with two uses in mind: 1) points with local attributes for visualizing differences in condition along lines and 2) polylines with summary attributes for strategic planning. First, regular sample points are generated along each polyline with the spacing set by the user (100-m is recommended). Then, input data values are extracted within a sample area around each point based on the radius provided by the user (60-m is recommended). Each polyline and associated sample points are assigned matching line identifier (LID) attributes for relating their data tables. The polyline summary statistics are then calculated from the points associated with each line. The outputs include shapefiles of both the sample points and summary line features.

![image](https://github.com/bengannon-fc/Line_analysis/assets/81584637/f2f95ab4-6610-4f74-9378-c8f072675a85)

**Instructions for Use**

*R software*

The line analysis workflow consists of three R scripts. R or R Studio are both available for installation from the USDA Software Center or directly from the organization websites. The workflow was developed and tested on R version 4.5. The spatial analysis is handled with the terra package (tested on version 1.8-93.) 

*Spatial data prep*

Compile all lines of interest into a single polyline shapefile. The only requirement is that it must have a spatial projection defined. Features should be singlepart; if not, they will be converted to singlepart in the script, which could have consequences if you have assigned your lines unique identifying names or numbers. This workflow will not clean your data. If you put junk in, you will get junk out. For most applications, you should avoid duplicates, overlaps, spurs, and large gaps, but these are not requirements to run the workflow. There is no minimum or maximum line length. The analyst is responsible for considering what scale of analysis is relevant to answer the management question.

It is optional to provide a single polygon shapefile of the fire extent if running the supplementary map workflow. The only requirement is that it must have a spatial projection defined.

*Controlling the workflow inputs*

The user should not need to modify the scripts except to set the working directory locations. The best practice is to pick a stable location for the workflow on your hard drive to avoid frequent changes to the working directory paths.

All other settings are controlled through an Excel workbook. The “Settings” worksheet is used to set up the run name, optional map text, geospatial extraction specifications, analysis lines input, and optional perimeter input. Follow the format provided in the template and the instructions in the description column. The “Rasters” worksheet is used to describe the names, locations, and extraction summary statistic for each raster dataset. If using the optional mapping and barplot workflows, you can define the data value break points, class names, and colors to use for maps and barplots. Note the comments in the header row to explain what each column controls and how to format your inputs. File paths should use forward slashes and match the capitalization of all directory and file names. 

*Suggested inputs*

Lines are typically attributed with indicators of suppression difficulty, potential for control, and firefighter safety. If you request this analysis from the Strategic Analytics Branch, we will extract the “first four Risk Management Assistance Analytics (RMA)” plus indicators of prior fire activity and treatment during the last decade. The RMA Analytics data can be found on the T Drive for Forest Service Employees or the RMA SharePoint for external users.

