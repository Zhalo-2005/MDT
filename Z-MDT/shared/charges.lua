Config.Charges = {
    -- Traffic Violations
    {
        category = "Traffic Violations",
        charges = {
            {code = "T001", title = "Speeding (Minor)", fine = 150, points = 3},
            {code = "T002", title = "Speeding (Major)", fine = 300, points = 6},
            {code = "T003", title = "Reckless Driving", fine = 500, points = 9},
            {code = "T004", title = "Running Red Light", fine = 200, points = 3},
            {code = "T005", title = "Illegal Parking", fine = 100, points = 0},
            {code = "T006", title = "No Insurance", fine = 1000, points = 6},
            {code = "T007", title = "No License", fine = 750, points = 3},
            {code = "T008", title = "Driving Under Influence", fine = 2000, points = 12}
        }
    },
    -- Criminal Offenses
    {
        category = "Criminal Offenses",
        charges = {
            {code = "C001", title = "Theft", fine = 1500, points = 0},
            {code = "C002", title = "Assault", fine = 2000, points = 0},
            {code = "C003", title = "Drug Possession", fine = 3000, points = 0},
            {code = "C004", title = "Weapon Possession", fine = 5000, points = 0},
            {code = "C005", title = "Robbery", fine = 7500, points = 0},
            {code = "C006", title = "Murder", fine = 15000, points = 0}
        }
    },
    -- Public Order
    {
        category = "Public Order",
        charges = {
            {code = "P001", title = "Disturbing Peace", fine = 250, points = 0},
            {code = "P002", title = "Public Intoxication", fine = 300, points = 0},
            {code = "P003", title = "Vandalism", fine = 500, points = 0},
            {code = "P004", title = "Trespassing", fine = 400, points = 0}
        }
    }
}
