"""Refresh the offline catalog from a local mledoze/countries countries.json snapshot."""
import hashlib
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
raw = source.read_bytes()
countries = [c for c in json.loads(raw) if c.get('independent') or c['cca2'] in ('PS', 'TW', 'XK')]
lookup = {c['cca3']: c['cca2'] for c in countries}
first = ['US', 'FR', 'EG', 'TR', 'JP']
countries.sort(key=lambda c: (first.index(c['cca2']) if c['cca2'] in first else 5, c['name']['common']))
art_by_region = {
    'Western Europe': 0, 'Central Europe': 0, 'Southern Europe': 1,
    'Southeast Europe': 1, 'Eastern Europe': 2, 'Eastern Asia': 3,
    'Western Asia': 4, 'Australia and New Zealand': 5, 'Northern Europe': 6,
    'South America': 7, 'Central Asia': 10, 'Southern Asia': 11,
    'South-Eastern Asia': 11, 'Eastern Africa': 12, 'Southern Africa': 12,
    'Middle Africa': 12, 'Western Africa': 12, 'Northern Africa': 4,
    'North America': 0, 'Central America': 14, 'Caribbean': 15,
    'Melanesia': 15, 'Micronesia': 15, 'Polynesia': 15,
}
art_overrides = {'GR': 8, 'CY': 8, 'MT': 8, 'ES': 9, 'PT': 9, 'AD': 9,
                 'MN': 10, 'CA': 6, 'MX': 14, 'CL': 13, 'BO': 13, 'PE': 13,
                 'EC': 13, 'CO': 13, 'AR': 13, 'UY': 7, 'PY': 7, 'VE': 7}
colors = ['91b8b0', 'd9ac85', 'bb9aa7', '91bca5', 'dcb475', '69afc4',
          '8cb8cf', '73bba0', '89bcd1', 'd9a28b', 'b2ad94', '81b7b0',
          'd0b87e', 'aeb8be', 'c3a58b', '76c2c4']
result = {}
for c in countries:
    code = c['cca2']
    region = c['subregion'] or c['region']
    art = art_overrides.get(code, art_by_region.get(region, 0))
    name = {'TR': 'Turkey', 'AE': 'United Arab Emirates (Dubai)'}.get(code, c['name']['common'])
    result[code] = {'name': name, 'region': region,
                    'neighbors': sorted(lookup[n] for n in c['borders'] if n in lookup),
                    'color': colors[art], 'art': art, 'capital': c['capital'],
                    'aliases': ' '.join(c.get('altSpellings', []))}
# The source can list a border on only one side; travel edges are undirected.
for code, country in result.items():
    for neighbor in list(country['neighbors']):
        if code not in result[neighbor]['neighbors']:
            result[neighbor]['neighbors'].append(code)
for country in result.values():
    country['neighbors'].sort()
assert len(result) == 197 and all(n in result for c in result.values() for n in c['neighbors'])
root = Path(__file__).resolve().parent.parent
(root / 'resources/geography/destinations.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
(root / 'resources/geography/SOURCE.txt').write_text(
    'Country data adapted from https://github.com/mledoze/countries (ODbL-1.0).\n'
    'Retrieved 2026-10-02; source countries.json SHA-256: ' + hashlib.sha256(raw).hexdigest() + '\n'
    'Includes independent entries plus Palestine, Taiwan, Kosovo; 197 travel destinations.\n'
    'Country names, capitals, subregions, and filtered land-border neighbors are snapshot data.\n'
    'Dubai is offered under the United Arab Emirates; artwork is stylized regional scenery.\n')
print(f'Imported {len(result)} destinations')

# Extra countries/territories remain separate from the immutable ranked catalog.
all_countries = json.loads(raw)
all_lookup = {c['cca3']: c['cca2'] for c in all_countries}
extra = {}
for c in sorted(all_countries, key=lambda item: item['name']['common']):
    code = c['cca2']
    if code in result:
        continue
    region = c['subregion'] or c['region'] or 'Polar regions'
    art = art_overrides.get(code, art_by_region.get(region, 15))
    extra[code] = {'name': c['name']['common'], 'region': region, 'kind': 'territory',
                   'neighbors': sorted(all_lookup[n] for n in c['borders'] if n in all_lookup),
                   'color': colors[art], 'art': art, 'capital': c['capital'],
                   'aliases': ' '.join(c.get('altSpellings', [])), 'stamp': code}
    if code in ('AQ', 'GL', 'BV', 'GS', 'HM', 'TF', 'SJ'):
        extra[code]['landmark_atlas'] = 1
        extra[code]['art'] = 3
        extra[code]['color'] = '8faac8'
(root / 'resources/geography/territories.json').write_text(json.dumps(extra, ensure_ascii=False, indent=2) + '\n')
print(f'Imported {len(extra)} additional territory destinations; ranked country catalog unchanged')

with (root / 'resources/geography/SOURCE.txt').open('a') as attribution:
    attribution.write(f'The separate territories.json adapts {len(extra)} additional country/territory entries from the same snapshot under ODbL-1.0.\n')
