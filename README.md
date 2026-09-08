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

### Network-based velocities

When the input network is set to `SIRGAS`, station coordinates and velocities are obtained from official SIRGAS files. This option is recommended when the station is part of the SIRGAS network and official coordinates and velocities are available.

### VEMOS models

For manually provided coordinates, the user may select regional velocity models from the VEMOS family, including:

- VEMOS2022
- VEMOS2017
- VEMOS2009
- VEMOS2003

These models provide regional velocity information for South America and can be used when station-specific velocities are not available.

### Euler pole model

The user may provide angular velocity components:

- Ωx
- Ωy
- Ωz

in radians per million years. The software then computes ECEF velocity components using a rigid plate rotation model.

### User-defined velocities

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

The software downloads the corresponding SIRGAS-CON coordinate solution in CRD format and extracts the coordinates of the selected station. An active Internet connection is therefore required when using this module.

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

This module accesses external ITRF data to retrieve the required station information and therefore requires an active Internet connection.

## Requirements

A-TREVel requires MATLAB to run. The software was developed and tested using **MATLAB R2025a**, which is therefore the recommended release. Compatibility with earlier MATLAB releases has not been systematically evaluated.

The graphical user interface was developed using MATLAB App Designer and is provided through the `apppolo_trevel.mlapp` file.

All source files and auxiliary functions included in the A-TREVel repository should be kept in the repository folder or otherwise remain accessible through the MATLAB path.

An Internet connection is not required for all A-TREVel operations. However, it is required for functionalities that retrieve external geodetic products. See the **Internet Requirements** section below.

## Installation

A-TREVel can be installed by cloning the repository:

```bash
git clone https://github.com/zaupa-jp/A-TREVel.git
