# applications_clock

## Introduction
The clock application can implement hte stopwatch timing function and countdown function.
The clock application is developed using the extended TS language (ArkTS), and its main structure is as follows:
![](./figures/clock.png)
- **Product**
  Business form layer：Business form layer: Distinguish different products, different screens of various forms of application, including personalized services, component configuration, and personalized resource packages.(To distinguish between tablet and default device forms, different products have different page layouts, mobile phone configurations, and accessible voice resources.)

- **Feature**
  Common Feature layer：An abstract collection of common feature components that can be referenced by various application forms, contains UI encapsulation components and logic controllers corresponding to the features.(Such as page files, TimerPick components for timers, etc.)

- **Common**
  Common Capability Layer：Basic capability set, a module that every application form must rely on, including universal UI encapsulation components, utility classes, and universal resource packages.(Such as adding an alarm button and adding a world clock button, alarm clock dial, and world clock dial.)

## Directory
### Directory structure
```
/clock/
├── common                    # Common capability level directory
├── feature                   # Public feature layer directory
│   ├── countdown             # Countdown function directory
│   │   └── components        # Countdown UI Package Component Catalog
│   │   └── controller        # Countdown control logic directory
│   └── timer                 # Stopwatch function directory
│       └── components        # Stopwatch UI Package Component Catalog
│       └── controller        # Stopwatch control logic directory
├── product                   # Business form layer directory
```
## Install
After the application is signed and packaged, run the hdc_std install "hap package address" command to install the application.
![](./figures/signature.png)
![](./figures/buildHap.png)
![](./figures/install.png)

## Restraint
- Development environment
  - **DevEco Studio for OpenHarmony**: The Version number is greater than 3.0.0.992, download and install OpenHarmony SDK API Version 9. (You can refer to the IDE documentation for initial IDE configuration.)
- Language version
  - ArkTS
- Restrict
  - This example only supports running on standard systems
