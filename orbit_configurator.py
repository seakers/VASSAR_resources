import os
import xlrd
import xlwt
import math
import numpy as np
import textdistance
from tqdm import tqdm
from openpyxl import Workbook
from openpyxl.styles import NamedStyle

from poliastro.bodies import Earth
from poliastro.twobody.orbit import Orbit
from astropy import units as u
from poliastro.constants import J2000
from poliastro.frames import Planes
import pandas as pd

earth_rad = 6378.14  # km

all_prev_orbits = [
    'GEO-36000-equat-NA',
    'LEO-275-polar-NA',
    'LEO-400-polar-NA',
    'LEO-600-polar-NA',
    'LEO-800-polar-NA',
    'SSO-400-SSO-DD',
    'SSO-400-SSO-AM',
    'SSO-400-SSO-noon',
    'SSO-400-SSO-PM',
    'SSO-600-SSO-DD',
    'SSO-600-SSO-AM',
    'SSO-600-SSO-noon',
    'SSO-600-SSO-PM',
    'SSO-800-SSO-DD',
    'SSO-800-SSO-AM',
    'SSO-800-SSO-noon',
    'SSO-800-SSO-PM',
    'LEO-275-equat-NA',
    'LEO-1000-near-polar-NA',
    'LEO-1300-near-polar-NA',
    'LEO-600-near-polar-NA',
    'SSO-1000-SSO-AM',
    'LEO-600-equat-NA'
]

all_fractions = [
    0.99,
    0.65,
    0.68,
    0.73,
    0.77,
    0.89,
    0.62,
    0.61,
    0.62,
    0.93,
    0.65,
    0.64,
    0.65,
    0.95,
    0.67,
    0.66,
    0.67,
    0.34,
    0.75,
    0.75,
    0.70,
    0.75,
    0.70
]

worst_angles = [
    23.44,
    113.44,
    113.44,
    113.44,
    113.44,
    120.46,
    120.46,
    120.46,
    120.46,
    121.22,
    121.22,
    121.22,
    121.22,
    122.04,
    122.04,
    122.04,
    122.04,
    23.44,
    89.44,
    89.44,
    89.44,
    122.44,
    89.44
]

max_eclipse_times = [
    4048,
    2200,
    2145,
    2110,
    2090,
    1453,
    2107,
    2147,
    2118,
    1199,
    2062,
    2111,
    2076,
    959,
    2033,
    2091,
    2049,
    5000,
    1000,
    1000,
    2110,
    1000,
    2110
]






class OrbitConfigurator:
    def __init__(self):
        print('Hello world!')
        self.file_path = '/Users/gapaza/repos/seakers/VASSAR_resources/problems/GigaProblem/xls'
        self.file_name = 'Orbits.xlsx'
        self.workbook_path = os.path.join(self.file_path, self.file_name)

        self.headers = ['id', 'type', 'altitude', 'inclination', 'RAAN#', 'fraction-of-sunlight#', 'period#', 'worst-sun-angle#', 'max-eclipse-time#']

        self.unique_orbits = [
            'LEO-275-polar-NA',
            'LEO-275-equat-NA',
            'GEO-36000-equat-NA'
        ]

        self.step_size = 20  # km
        self.enum_orbits = {
            'LEO-X-polar-NA': [300, 800 + self.step_size],
            'LEO-X-equat-NA': [300, 600 + self.step_size],
            'SSO-X-SSO-DD': [400, 800 + self.step_size],
            'SSO-X-SSO-AM': [400, 1000 + self.step_size],
            'SSO-X-SSO-noon': [400, 800 + self.step_size],
            'SSO-X-SSO-PM': [400, 800 + self.step_size],
            'LEO-X-near-polar-NA': [600, 1300 + self.step_size],
        }

    def create_workbook(self):
        if not os.path.isfile(self.workbook_path):
            workbook = xlwt.Workbook()
            sheet = workbook.add_sheet("Orbits")
            workbook.save(self.workbook_path)


    def get_orbits(self):
        all_orbits = []
        for key, value in self.enum_orbits.items():
            replacements = list(range(value[0], value[1], self.step_size))
            new_orbits = [key.replace('X', str(number)) for number in replacements]
            all_orbits.extend(new_orbits)

        return all_orbits


    def get_orbit_rows(self):
        all_orbits = self.get_orbits()

        orbit_rows = []

        progress_bar = tqdm(total=len(all_orbits), desc='Adding orbits')
        for idx, orbit in enumerate(all_orbits):
            orbit_type = orbit.split('-')[0]
            orbit_altitude = int(orbit.split('-')[1])
            orbit_period = get_orbit_period(orbit_altitude)
            orbit_raan = orbit.split('-')[-1]
            if 'near-polar' in orbit:
                orbit_inclination = 66
            else:
                orbit_inclination = orbit.split('-')[2]
                if orbit_inclination == 'equat':
                    orbit_inclination = 0
                elif orbit_inclination == 'polar':
                    orbit_inclination = 90
                elif orbit_inclination == 'SSO':
                    orbit_inclination = get_sso_inclination(orbit_altitude)
                else:
                    raise ValueError('Unknown orbit inclination: {}'.format(orbit_inclination))


            similar_idx = get_similar_orbit_idx(orbit)
            frac_of_sunlight = all_fractions[similar_idx]
            worst_sun_angle = worst_angles[similar_idx]
            max_eclipse_time = max_eclipse_times[similar_idx]

            orbit_row = [orbit, orbit_type, orbit_altitude, orbit_inclination, orbit_raan, frac_of_sunlight, orbit_period, worst_sun_angle, max_eclipse_time]
            orbit_rows.append(orbit_row)
            progress_bar.update(1)

        # sort orbit_rows first on third item and second on first item
        orbit_rows.sort(key=lambda x: (x[2], x[0]))
        return orbit_rows

    def fill_sheet(self):
        orbit_rows = self.get_orbit_rows()

        df = pd.DataFrame(orbit_rows, columns=self.headers)

        # Create a workbook and add a worksheet to it
        workbook = Workbook()
        sheet = workbook.active
        sheet.title = 'Sheet1'

        # Apply a percentage style to the 'fraction-of-sunlight#' column
        percentage_style = NamedStyle(number_format='0.00%')

        # Add headers to the sheet
        for col_num, header in enumerate(self.headers, 1):
            col_letter = chr(64 + col_num)
            sheet[f'{col_letter}1'] = header

        # Add data rows to the sheet
        for row_num, row in enumerate(orbit_rows, 2):
            for col_num, cell_value in enumerate(row, 1):
                col_letter = chr(64 + col_num)
                sheet[f'{col_letter}{row_num}'] = cell_value

        # Save the workbook
        workbook.save(filename=self.workbook_path)



def get_similar_orbit_idx(orbit):
    # find string in all_prev_orbits list with closest distance to orbit string using textdistance
    min_dist = 100000
    min_idx = 0
    for idx, prev_orbit in enumerate(all_prev_orbits):
        dist = textdistance.levenshtein.distance(orbit, prev_orbit)
        # print('Distance between {} and {} is {}'.format(orbit, prev_orbit, dist))
        if dist < min_dist:
            min_dist = dist
            min_idx = idx
    # print('Closest orbit to {} is {}'.format(orbit, all_prev_orbits[min_idx]))
    return min_idx


def get_sso_inclination(alt=400):
    altitude = alt * u.km
    earth_rad = 6378.137 * u.km
    a = altitude + earth_rad
    ecc = 0 * u.one   # Eccentricity, 0 for circular orbit
    raan = 0 * u.deg  # Right ascension of the ascending node
    argp = 0 * u.deg  # Argument of the pericenter
    nu = 0 * u.deg    # True anomaly
    epoch = J2000     # Epoch, default to J2000
    plane = Planes.EARTH_EQUATOR  # Fundamental plane of the frame
    orbit = Orbit.heliosynchronous(Earth, a=a, ecc=ecc, raan=raan, argp=argp, nu=nu, epoch=epoch, plane=plane)

    inclination = orbit.inc
    inclination = inclination.to(u.deg)
    inclination = round(float(inclination.value), 2)
    # print(inclination)
    return inclination


def get_orbit_period(alt=1300):
    mu = 3.986e14  # gravitational parameter of Earth, m³/s²
    Re = 6378.137  # Earth radius in km
    a = (Re + alt) * 1000  # Semi-major axis in meters
    T = 2 * math.pi * math.sqrt(a ** 3 / mu)
    T = round(T / 60, 0)  # Orbital period in minutes, round
    # print(T)
    return T  # Orbital period in seconds



if __name__ == '__main__':
    config = OrbitConfigurator()
    config.fill_sheet()






