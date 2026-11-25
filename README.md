# DriveScan

Hey there! 

DriveScan is a free alternative to Codify, however right now it only supports pure LuaU and Vide(TypeScript for both of them will be added, but not very soon since I have to do some work first).

### Types

#### `Mode: "Pure" | "Vide" | "Flux"`
Used in Scan() to output specific syntax.

### Methods

#### `DriveScan.Scan(Root: ScreenGui, Type: Mode): string`
Returns a string, which is basically generated code in luau or vide.
* `Root`: Given ScreenGui to analyze all the structure inside.
* `Type`: Output setting to generate code in luau, vide or flux.

#### `DriveScan.Analyze(Root: Folder, Type: Mode): string`
Analyzes given folder and applies Scan() for every found ScreenGui in it.
* `Root`: Given Folder to analyze all the structure inside.
* `Type`: Output setting to generate code in luau, vide or flux.

#### `DriveScan.Print(Value: string, Size: number?):()`
Prints the text through a bunch of prints if exceeded the limit.
* `Value`: Given string. Usually used in pair with DriveScan.Scan.
* `Size`: Given symbol limit. 16.000 by default.

#### `DriveScan.Cache():()`
Clears cached instances. You probably wouldn't want to use it unless you know what you're doing.

#### `DrivenScan.showProgress: boolean`
If it is turned on, prints every progress' step. Turned off by default.

**Example:**
```
local ds = require(game:GetService("ReplicatedStorage").Packages.drivescan)
local sg = game:GetService("StarterGui"):WaitForChild("thissg")

ds.Print(ds.Scan(sg, "Vide"))
```
As you can see, this module is disposable. You probably would want to create init script to generate code through given ScreenGui and then just delete it.
