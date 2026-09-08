# A-TREVel

**A-TREVel** is an open-source MATLAB toolbox for time-dependent coordinate transformation between Terrestrial Reference Frame (TRF) realizations. The software was developed as part of the APPPOLO project and provides a graphical environment for coordinate updating, coordinate conversion, retrieval of SIRGAS-CON coordinates, and access to ITRF station coordinates and velocities.

A-TREVel implements time-dependent Helmert transformations following the IERS formulation and explicitly separates station temporal propagation from reference frame transformation. This distinction allows the user to update coordinates between different epochs and reference frame realizations while accounting for station velocities and, when available, formal uncertainty propagation.

## Main Features

- Time-dependent coordinate transformation between TRF realizations;
- Support for SIRGAS and ITRF reference frames;
- Coordinate propagation between different epochs;
- Velocity modeling using:
  - official SIRGAS/network velocities;
  - VEMOS regional velocity models;
  - Euler pole angular velocity parameters;
  - user-defined ECEF velocity components;
- Optional formal covariance propagation;
- Coordinate conversion between geodetic and geocentric systems;
- Retrieval of SIRGAS-CON weekly coordinates;
- Retrieval and propagation of ITRF2020 station coordinates;
- MATLAB graphical user interface developed with App Designer.

## Supported Reference Frames

The current version supports the following reference frames:

- SIRGAS2000
- SIRGAS2022
- ITRF97
- ITRF2000
- ITRF2005
- ITRF2008
- ITRF2014
- ITRF2020

When direct transformation parameters between two realizations are not available, A-TREVel can apply a chain of intermediate transformations according to the availability of official ITRF transformation parameters.

## Velocity Models

A-TREVel supports different velocity modeling strategies.

### Network-based Velocities

When the input network is set to `SIRGAS`, station coordinates and velocities are obtained from official SIRGAS files. This option is recommended when the station is part of the SIRGAS network and official coordinates and velocities are available.

### VEMOS Models

For manually provided coordinates, the user may select regional velocity models from the VEMOS family, including:

- VEMOS2022
- VEMOS2017
- VEMOS2009
- VEMOS2003

These models provide regional velocity information for South America and can be used when station-specific velocities are not available.

### Euler Pole Model

The user may provide angular velocity components:

- Ωx
- Ωy
- Ωz

in radians per million years. The software then computes ECEF velocity components using a rigid plate rotation model.

### User-defined Velocities

The user may directly provide ECEF velocity components:

- Vx
- Vy
- Vz

in meters per year. When formal covariance propagation is enabled, standard deviations for both position and velocity components can also be provided.

## Graphical Interface

The software is organized into four main tabs.

### 1. Update Coordinates

This is the main module of A-TREVel. It allows the user to transform and propagate coordinates between reference frames and epochs.

The user can define:

- initial reference frame;
- final reference frame;
- initial epoch;
- final epoch;
- network type;
- coordinate type;
- station code or manual coordinates;
- velocity model;
- covariance propagation options.

Input coordinates can be provided as:

- Cartesian coordinates: `X`, `Y`, `Z` in meters;
- Geodetic coordinates: latitude, longitude, and ellipsoidal height.

The output is displayed directly in the graphical interface.

### 2. Coordinates Conversion

This module converts coordinates between:

- geocentric Cartesian coordinates: `X`, `Y`, `Z`;
- geodetic coordinates: latitude, longitude, and ellipsoidal height.

Several reference ellipsoids are available, including:

- GRS80
- WGS84
- WGS72
- PZ90
- CGCS2000
- NAD83
- NAD27
- and others.

### 3. SIRGAS-CON

This module retrieves SIRGAS-CON weekly coordinates for a selected station and date. The user provides:

- station code;
- date.

The software downloads the corresponding SIRGAS-CON coordinate solution in CRD format and extracts the coordinates of the selected station.

An active Internet connection is required to use this module.

### 4. ITRF-Updates

This module retrieves and propagates ITRF2020 station coordinates using official ITRF station solutions. The user provides:

- ITRF realization;
- station code;
- requested date.

The supported ITRF2020 realizations are:

- ITRF2020
- ITRF2020u2023
- ITRF2020u2024

The output includes reference coordinates, velocities, propagated coordinates, and the time difference from the reference epoch.

An active Internet connection is required to access the external ITRF data used by this module.

## Requirements

A-TREVel requires MATLAB to run. The software was developed and tested using **MATLAB R2025a**, which is therefore the recommended release. Compatibility with earlier MATLAB releases has not been systematically evaluated.

The graphical user interface was developed using MATLAB App Designer and is provided through the `apppolo_trevel.mlapp` file. App Designer is part of the MATLAB environment and does not require a separate plugin or add-on for running the application.

All source files and auxiliary functions included in the A-TREVel repository should be kept in the repository folder or otherwise remain accessible through the MATLAB path.

An Internet connection is required only for modules that retrieve external geodetic products, as described in the **Internet Requirements** section.

## Installation

Clone the repository:

```bash
git clone https://github.com/zaupa-jp/A-TREVel.git
```

Alternatively, download the repository as a ZIP file from GitHub and extract it to a local folder.

No additional installation procedure is required. The application and its auxiliary MATLAB functions are provided directly in the repository.

## Quick Start

To start A-TREVel:

1. Install MATLAB. MATLAB R2025a is recommended because this is the release in which A-TREVel was developed and tested.
2. Download or clone the A-TREVel repository.
3. Open MATLAB.
4. Set the MATLAB **Current Folder** to the A-TREVel repository folder.
5. Locate the `apppolo_trevel.mlapp` file in the MATLAB Current Folder browser.
6. Double-click `apppolo_trevel.mlapp` to open the application in MATLAB App Designer.
7. Click **Run** to launch A-TREVel.

The main graphical interface will open with the four available modules:

- **Update Coordinates**
- **Coordinates Conversion**
- **SIRGAS-CON**
- **ITRF-Updates**

For a first calculation involving coordinate updating, select the **Update Coordinates** tab.

## First Example: Updating Station Coordinates

The following example illustrates a basic coordinate update and can also be used to verify that A-TREVel is running correctly.

### Example Input

In the **Update Coordinates** module, use the following configuration:

- **Initial reference frame:** ITRF2014
- **Target reference frame:** ITRF2020
- **Initial epoch:** `[INITIAL EPOCH]`
- **Target epoch:** `[TARGET EPOCH]`
- **Coordinate type:** Cartesian
- **X:** `[X]` m
- **Y:** `[Y]` m
- **Z:** `[Z]` m
- **Velocity model:** User-defined
- **Vx:** `[VX]` m/year
- **Vy:** `[VY]` m/year
- **Vz:** `[VZ]` m/year

### Procedure

1. Open A-TREVel by running `apppolo_trevel.mlapp`.
2. Select the **Update Coordinates** tab.
3. Select `ITRF2014` as the initial reference frame.
4. Select `ITRF2020` as the target reference frame.
5. Enter the initial and target epochs given above.
6. Select Cartesian coordinates as the input coordinate type.
7. Enter the `X`, `Y`, and `Z` coordinates.
8. Select the user-defined velocity option.
9. Enter `Vx`, `Vy`, and `Vz`.
10. Run the coordinate update.

### Expected Output

For the input values above, A-TREVel should return approximately:

- **X:** `[EXPECTED X]` m
- **Y:** `[EXPECTED Y]` m
- **Z:** `[EXPECTED Z]` m

Small differences in the last displayed decimal places may occur due to numerical precision.

This example provides a simple verification of the coordinate temporal propagation and reference frame transformation procedures implemented in A-TREVel.

## Internet Requirements

Most calculations performed by A-TREVel use the functions and data distributed with the repository and do not require a continuous Internet connection.

An active Internet connection is required for the following modules:

- **SIRGAS-CON:** Internet access is required to download the corresponding SIRGAS-CON CRD solution files used to retrieve weekly station coordinates.
- **ITRF-Updates:** Internet access is required to access the external ITRF data used to retrieve ITRF2020 station coordinates and velocity information, including the supported ITRF2020 update realizations.

The **Update Coordinates** and **Coordinates Conversion** modules do not inherently require Internet access when all required input data and auxiliary files are locally available.

## Typical Workflow

A typical A-TREVel coordinate transformation consists of:

1. defining the input coordinates and their reference epoch;
2. selecting the input and target TRF realizations;
3. defining the target epoch;
4. selecting or providing the station velocity model;
5. propagating the station coordinates to the target epoch;
6. propagating the Helmert transformation parameters to the target epoch;
7. transforming the coordinates to the target TRF realization;
8. optionally propagating the available formal covariance information.

A-TREVel explicitly distinguishes the temporal propagation of station coordinates from the temporal evolution of the Helmert transformation parameters.

## Notes on Uncertainty Propagation

When uncertainty information is available, A-TREVel can propagate the formal covariance contributions associated with station coordinates, station velocities, and Helmert transformation parameters.

The current stochastic implementation assumes independence between coordinates, velocities, Helmert parameters and their rates, and different transformation links when complete joint covariance information is unavailable. Cross-covariance terms are therefore neglected.

The resulting uncertainties should be interpreted as **first-order formal uncertainty estimates under these assumptions**, rather than as complete measures of actual coordinate accuracy.

## License

A-TREVel is distributed as an open-source MATLAB toolbox. Please refer to the license file included in the repository for the applicable terms of use.

## Citation

If A-TREVel contributes to your research, please cite the associated publication describing the software, transformation methodology, velocity modeling strategies, and experimental evaluation.
