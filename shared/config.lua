Config = {}

-- Basic Info
Config['Version'] = 3.2 -- DO NOT TOUCH
Config['Locale'] = 'en' -- 'es' or 'en'

-- Webhook Settings
Config['EnableWebhook'] = false
Config['Webhook'] = "" -- Your webhook URL
Config['CommunityName'] = "Nekix Vehicle Shop Logs"
Config['CommunityLogo'] = "https://cdn.discordapp.com/icons/838115320597446677/a96dc72395659c8d3921bece0ac2039d?size=256"
Config['Avatar'] = "https://cdn.discordapp.com/icons/838115320597446677/a96dc72395659c8d3921bece0ac2039d?size=256"

-- Vehicle Shop Settings
Config['VS'] = {
    ['PressKey'] = 38, -- E key
    ['NeedLicense'] = false, -- Enable license check
    ['LicenseRequired'] = 'drive', -- License type required if NeedLicense=true
    ['PersonalizedPlate'] = true, -- Allow custom plates
    ['RandomPlate'] = false, -- Use random letters/numbers if true
    ['TestTime'] = 1, -- Test drive duration in minutes
    ['BackToVSAfterTest'] = true, -- Teleport back after test

    ['Menu'] = {
        {label = "Test de conducción del coche", value = 'test'},
        {label = "Inserta Matrícula Personalizada", value = 'plate'},
        {label = "Pagar con Dinero en Mano", value = 'money'},
        {label = "Pagar con Dinero del Banco", value = 'bank'}
    },

    ['Blips'] = {
        {
            ['x'] = 222.1689,
            ['y'] = -852.3805,
            ['z'] = 30.06906,
            ['sprite'] = 523,
            ['color'] = 47,
            ['scale'] = 0.75,
            ['label'] = "Concesionario VIP",
        },
        {
            ['x'] = -53.45557,
            ['y'] = -1116.232,
            ['z'] = 26.435,
            ['sprite'] = 523,
            ['color'] = 47,
            ['scale'] = 0.75,
            ['label'] = "Vehicle Shop 2",
        }
    },

    ['Cars'] = {
        {
            ['model'] = 'blista',
            ['label'] = "Blista",
            ['price'] = 4000,
            ['x'] = 227.5898,
            ['y'] = -873.8725,
            ['z'] = 30.4921,
            ['r'] = -12.9241,
            ['spawner'] = 'Test1'
        },
        {
            ['model'] = 'bati',
            ['label'] = "Bati",
            ['price'] = 1000,
            ['x'] = -53.45557,
            ['y'] = -1116.232,
            ['z'] = 26.435,
            ['r'] = 7.3242,
            ['spawner'] = 'Test2'
        },
    },

    ['Spawners'] = {
        ['Test1'] = {
            ['x'] = 222.1689,
            ['y'] = -852.3805,
            ['z'] = 31.06906,
            ['r'] = -110.8709
        },
        ['Test2'] = {
            ['x'] = -30.98,
            ['y'] = -1089.839,
            ['z'] = 27.0,
            ['r'] = 334.4646
        },
    },

    ['Sellers'] = {
        ['Percentage'] = 50, -- 50% back to seller
        ['Locations'] = {
            {
                ['x'] = -45.24,
                ['y'] = -1083.221,
                ['z'] = 26.721,
            },
        }
    }
}
