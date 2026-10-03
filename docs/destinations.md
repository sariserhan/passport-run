# World destinations

250 free countries and territories, including every country explicitly requested. Dubai appears as **United Arab Emirates (Dubai)**, code AE. Search by name, code or dataset alias in the home-country picker and passport. World Tour and Kids travel to unvisited destinations through land-border neighbors and periodic long-haul choices. New Daily tours retain 197 ranked countries; Infinite cycles through the 250 free destinations.

Country names, capitals, subregions and land-border links come from [mledoze/countries](https://github.com/mledoze/countries), downloaded 2026-10-02. The snapshot includes independent entries plus Palestine, Taiwan and Kosovo, yielding 197 game destinations. This is a travel catalog, not a statement about recognition. Filtered border edges are made reciprocal; islands use flights. Source hash and attribution are in `resources/geography/SOURCE.txt`. The adapted database is provided under ODbL-1.0; the full license is bundled in `resources/geography/LICENSE.txt`, exported with the game, and credited in the picker.

To update the snapshot, download that repository's countries.json locally and run `python3 tools/import_destinations.py /path/to/countries.json`, then verify Godot/backend route parity and review source changes. The game reads the JSON offline; Convex imports the exact same file. Changing deterministic catalog order or borders requires a new catalog version for ranked compatibility. Current catalog v2 preserves old catalog-v1 five-country retries and boards.

Artwork: all 282 destinations now have distinct images. Six country paintings (including Afghanistan) use dedicated PNGs; 244 other country/territory paintings use individually assigned cells across sixteen atlases, and the 32 paid locations retain their individual scenes. No destination shares a scene. `resources/geography/artwork.json` assigns the country atlas cells; regional metadata no longer selects country artwork. Every destination has scenery, stamps, stickers and capital/subregion reward text. Prompts and built-in imagegen provenance are in [visual asset notes](visual-assets.md).

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

## Additional free destinations

American Samoa, Anguilla, Antarctica, Aruba, Bermuda, Bouvet Island, British Indian Ocean Territory, British Virgin Islands, Caribbean Netherlands, Cayman Islands, Christmas Island, Cocos (Keeling) Islands, Cook Islands, Curaçao, Falkland Islands, Faroe Islands, French Guiana, French Polynesia, French Southern and Antarctic Lands, Gibraltar, Greenland, Guadeloupe, Guam, Guernsey, Heard Island and McDonald Islands, Hong Kong, Isle of Man, Jersey, Macau, Martinique, Mayotte, Montserrat, New Caledonia, Niue, Norfolk Island, Northern Mariana Islands, Pitcairn Islands, Puerto Rico, Réunion, Saint Barthélemy, Saint Helena, Ascension and Tristan da Cunha, Saint Martin, Saint Pierre and Miquelon, Sint Maarten, South Georgia, Svalbard and Jan Mayen, Tokelau, Turks and Caicos Islands, United States Minor Outlying Islands, United States Virgin Islands, Wallis and Futuna, Western Sahara, Åland Islands.

## Special Expeditions — separate purchase

Mount Everest, Sahara Desert, Grand Canyon, Machu Picchu, Petra, Taj Mahal, Angkor Wat, Northern Lights, Great Barrier Reef, Victoria Falls, Salar de Uyuni, Serengeti, Amazon Rainforest, Venice Canals, Stonehenge, Santorini, Underwater World, Space Station, Moon, Mars, Saturn Rings, Crystal Cavern, Cloud City, Dragon Island.

## Cinema Worlds — independent purchase

Hobbit Village, Elven Valley, Volcanic Realm, Wizard Castle, Wizard Village, Enchanted Forest, Dinosaur Island, Wonderland. Original movie-inspired compositions. Each paid route starts at the chosen destination and visits its own pack once. Paid places are excluded from free home selection and free routes; imported challenges enforce both ownership gates. See [purchase setup](purchases.md).
