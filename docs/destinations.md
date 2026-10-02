# World destinations

197 travel destinations, including every country explicitly requested. Dubai appears as **United Arab Emirates (Dubai)**, code AE. Search by name, code or dataset alias in the home-country picker and passport. World Tour and Kids travel to unvisited destinations through land-border neighbors and periodic long-haul choices. New Daily tours contain all 197 countries; Infinite cycles through the expanded catalog.

Country names, capitals, subregions and land-border links come from [mledoze/countries](https://github.com/mledoze/countries), downloaded 2026-10-02. The snapshot includes independent entries plus Palestine, Taiwan and Kosovo, yielding 197 game destinations. This is a travel catalog, not a statement about recognition. Filtered border edges are made reciprocal; islands use flights. Source hash and attribution are in `resources/geography/SOURCE.txt`. The adapted database is provided under ODbL-1.0; the full license is bundled in `resources/geography/LICENSE.txt`, exported with the game, and credited in the picker.

To update the snapshot, download that repository's countries.json locally and run `python3 tools/import_destinations.py /path/to/countries.json`, then verify Godot/backend route parity and review source changes. The game reads the JSON offline; Convex imports the exact same file. Changing deterministic catalog order or borders requires a new catalog version for ranked compatibility. Current catalog v2 preserves old catalog-v1 five-country retries and boards.

Artwork: five original destination paintings plus sixteen original illustrated regional scenes in `assets/world-backdrops.png`. Several countries share scenery; unique country landmark art remains future work. Every destination has scenery, stamps, stickers and capital/subregion reward text. Prompts and built-in imagegen provenance are in [visual asset notes](visual-assets.md).

## Coverage

**Australia and New Zealand**: Australia, New Zealand.

**Caribbean**: Antigua and Barbuda, Bahamas, Barbados, Cuba, Dominica, Dominican Republic, Grenada, Haiti, Jamaica, Saint Kitts and Nevis, Saint Lucia, Saint Vincent and the Grenadines, Trinidad and Tobago.

**Central America**: Belize, Costa Rica, El Salvador, Guatemala, Honduras, Nicaragua, Panama.

**Central Asia**: Kazakhstan, Kyrgyzstan, Tajikistan, Turkmenistan, Uzbekistan.

**Central Europe**: Austria, Czechia, Hungary, Poland, Slovakia, Slovenia.

**Eastern Africa**: Burundi, Comoros, Djibouti, Eritrea, Ethiopia, Kenya, Madagascar, Malawi, Mauritius, Mozambique, Rwanda, Seychelles, Somalia, Tanzania, Uganda, Zambia, Zimbabwe.

**Eastern Asia**: Japan, China, Mongolia, North Korea, South Korea, Taiwan.

**Eastern Europe**: Belarus, Moldova, Russia, Ukraine.

**Melanesia**: Fiji, Papua New Guinea, Solomon Islands, Vanuatu.

**Micronesia**: Kiribati, Marshall Islands, Micronesia, Nauru, Palau.

**Middle Africa**: Angola, Cameroon, Central African Republic, Chad, Congo, DR Congo, Equatorial Guinea, Gabon, South Sudan, São Tomé and Príncipe.

**North America**: United States, Canada, Mexico.

**Northern Africa**: Egypt, Algeria, Libya, Morocco, Sudan, Tunisia.

**Northern Europe**: Denmark, Estonia, Finland, Iceland, Ireland, Latvia, Lithuania, Norway, Sweden, United Kingdom.

**Polynesia**: Samoa, Tonga, Tuvalu.

**South America**: Argentina, Bolivia, Brazil, Chile, Colombia, Ecuador, Guyana, Paraguay, Peru, Suriname, Uruguay, Venezuela.

**South-Eastern Asia**: Brunei, Cambodia, Indonesia, Laos, Malaysia, Myanmar, Philippines, Singapore, Thailand, Timor-Leste, Vietnam.

**Southeast Europe**: Albania, Bosnia and Herzegovina, Bulgaria, Croatia, Kosovo, Montenegro, North Macedonia, Romania, Serbia.

**Southern Africa**: Botswana, Eswatini, Lesotho, Namibia, South Africa.

**Southern Asia**: Afghanistan, Bangladesh, Bhutan, India, Iran, Maldives, Nepal, Pakistan, Sri Lanka.

**Southern Europe**: Andorra, Cyprus, Greece, Italy, Malta, Portugal, San Marino, Spain, Vatican City.

**Western Africa**: Benin, Burkina Faso, Cape Verde, Gambia, Ghana, Guinea, Guinea-Bissau, Ivory Coast, Liberia, Mali, Mauritania, Niger, Nigeria, Senegal, Sierra Leone, Togo.

**Western Asia**: Turkey, Armenia, Azerbaijan, Bahrain, Georgia, Iraq, Israel, Jordan, Kuwait, Lebanon, Oman, Palestine, Qatar, Saudi Arabia, Syria, United Arab Emirates (Dubai), Yemen.

**Western Europe**: France, Belgium, Germany, Liechtenstein, Luxembourg, Monaco, Netherlands, Switzerland.

## Verification

Route checks cover every starting country, every requested destination, reciprocal borders, all artwork, and full-length challenge encoding. Backend checks include all 197 passport entries, coexistence with previously saved Daily challenges, legacy retries, deterministic routes and a complete 3,940-event hard tour. Native export includes catalog, license and atlas. `tools/capture_destinations.gd` checks Dubai search and captures all sixteen new scenery variants, passport and sticker screens. Desktop captures and signed builds do not establish physical-iPhone performance.
