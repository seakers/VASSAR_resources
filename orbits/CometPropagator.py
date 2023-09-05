from math import radians
import pandas as pd
import time
import numpy as np
import orekit
from orekit.pyhelpers import setup_orekit_curdir, download_orekit_data_curdir
from org.hipparchus.geometry.euclidean.threed import RotationOrder, Vector3D, RotationConvention
from org.orekit.attitudes import NadirPointing, YawSteering, LofOffset, FieldAttitude
from org.orekit.bodies import CelestialBodyFactory, OneAxisEllipsoid
from org.orekit.frames import FramesFactory, LOFType, StaticTransform
from org.orekit.orbits import KeplerianOrbit, PositionAngle
from org.orekit.propagation.analytical import EcksteinHechlerPropagator
from org.orekit.propagation.events import EclipseDetector, EventsLogger
from org.orekit.propagation.events.handlers import ContinueOnEvent
from org.orekit.time import AbsoluteDate
from org.orekit.time import TimeScalesFactory
from org.orekit.utils import Constants, IERSConventions
from org.orekit.utils import PVCoordinatesProvider
from math import radians, degrees

from pathlib import Path
import pickle, os




class CometPropagator:

    def __init__(self):
        self.orbit_db_path = '/Users/gapaza/repos/seakers/VASSAR_resources/orbit_info.pickle'
        self.orbit_db = {}
        self.load_orbit_db()


    def load_orbit_db(self):
        if Path(self.orbit_db_path).is_file() is False:
            self.save_orbit_db()
        else:
            db_file = open(self.orbit_db_path, 'rb')
            self.orbit_db = pickle.load(db_file)
            db_file.close()

    def save_orbit_db(self):
        if Path(self.orbit_db_path).is_file() is True:
            try:
                os.remove(self.orbit_db_path)
            except Exception as ex:
                print('--> ERROR REMOVING DB FILE')
        db_file = open(self.orbit_db_path, 'wb')
        pickle.dump(self.orbit_db, db_file)
        db_file.close()


    def get_propagation_info(self, model):
        orbit_key = model.get_variable('orbit')
        if orbit_key in self.orbit_db:
            print('--> ORBIT INFO EXISTS:', orbit_key)
            return self.orbit_db[orbit_key]
        else:
            print('--> NEW ORBIT:', orbit_key)
            return self.calc_propagation_info(model)



    def calc_propagation_info(self, model):

        # --> 1. Calc propagation info for a range of RAANs
        # - Select the RAAN which produces the highest number of eclipse events
        orbit = model.get_variable('orbit')
        # orbit = 'LEO-400-DD'
        max_eclipse = 0
        max_df = None
        raan_list = np.arange(0, 180, 5)
        for raan in raan_list:
            # print('--> PROPAGATING WITH RAAN:', raan)
            eclipses, df = self.propagate_orbit(model, raan=raan)
            num_eclipse = eclipses.count(True)
            if num_eclipse > max_eclipse:
                max_eclipse = num_eclipse
                max_df = df
                print('--> ECLIPSES:', raan, num_eclipse)


        self.orbit_db[orbit] = max_df
        self.save_orbit_db()

        return max_df


    def propagate_orbit(self, model=None, raan=None, period=None):

        vm = orekit.initVM()
        setup_orekit_curdir()

        # --> Model Inputs
        if model:
            altitude = model.get_variable('orbit altitude')  # altitude
            inclination = radians(model.get_variable('inclination'))
            eccentricity = model.get_variable('eccentricity')
            aop = radians(model.get_variable('argument of periapsis'))
            true_anomaly = radians(model.get_variable('true anomaly'))  # true anomaly
            epoch = [2020, 1, 1, 0, 0, 00.000]  # y/m/d/h/m/s
        else:
            altitude = 400  # Km
            inclination = radians(50.0)  # degrees
            eccentricity = 0.0  # [0, 1]
            aop = radians(0.0)           # degrees (argument of perigee)
            true_anomaly = radians(0.0)  # degrees
            epoch = [2020, 1, 1, 0, 0, 00.000]  # y/m/d/h/m/s


        one_year = 60 * 60 * 24 * 365
        one_month = 60 * 60 * 24 * 31
        orbit_period = period * 60.0  # seconds
        propagation_duration = orbit_period


        sma = float(altitude) * 1E3 + 6378137.0  # sma
        if raan is None:
            raan = radians(180)  # degrees (vary this parameter to get longest time eclipse for a whole orbit)
        else:
            raan = radians(raan)

        # -------------- #
        # --- Orekit --- #
        # -------------- #

        # --> 1. Orbit
        utc = TimeScalesFactory.getUTC()
        # --------- AbsoluteDate(int year, int month, int day, int hour, int minute, double second, TimeScale timeScale)
        start_date = AbsoluteDate(epoch[0], epoch[1], epoch[2], epoch[3], epoch[4], epoch[5], utc)
        inertial_frame = FramesFactory.getEME2000()
        keplerian_orbit = KeplerianOrbit(sma, eccentricity, inclination,
                                         aop, raan, true_anomaly,
                                         PositionAngle.TRUE, inertial_frame, start_date,
                                         Constants.WGS84_EARTH_MU)

        # --> 2. Bodies
        earth_frame = FramesFactory.getITRF(IERSConventions.IERS_2010, True)
        earth = OneAxisEllipsoid(Constants.WGS84_EARTH_EQUATORIAL_RADIUS,
                                 Constants.WGS84_EARTH_FLATTENING,
                                 earth_frame)

        sun = CelestialBodyFactory.getSun()
        sun_pv = PVCoordinatesProvider.cast_(sun)  # But we want the PVCoord interface

        # --> 3. Propagator + Eclipse Detector
        attitude_law = LofOffset(FramesFactory.getEME2000(), LOFType.VVLH, RotationOrder.XYZ, 0.0, 0.0, 0.0)
        propagator = EcksteinHechlerPropagator(keplerian_orbit, attitude_law,
                                               Constants.EIGEN5C_EARTH_EQUATORIAL_RADIUS,
                                               Constants.EIGEN5C_EARTH_MU, Constants.EIGEN5C_EARTH_C20,
                                               Constants.EIGEN5C_EARTH_C30, Constants.EIGEN5C_EARTH_C40,
                                               Constants.EIGEN5C_EARTH_C50, Constants.EIGEN5C_EARTH_C60)
        eclipse_detector = EclipseDetector(sun, Constants.SUN_RADIUS, earth).withUmbra().withHandler(ContinueOnEvent())
        logger = EventsLogger()
        logged_detector = logger.monitorDetector(eclipse_detector)
        propagator.addEventDetector(logged_detector)

        # --> 4. Execute Propagation
        time_step = 30.0  # sec

        num_steps = np.ceil(propagation_duration / time_step)
        discrete_times = np.arange(time_step, num_steps * time_step, time_step)

        dates = []
        eclipses = []
        satX = []
        satY = []
        satZ = []
        sunX = []
        sunY = []
        sunZ = []
        satpos = []
        sunpos = []
        print('--> STEPS:', len(discrete_times))
        for idx, t_shift in enumerate(discrete_times):
            print('-->', idx)
            state = propagator.propagate(start_date, start_date.shiftedBy(float(t_shift)))
            sat_position = state.getPVCoordinates().getPosition()
            sun_position = sun_pv.getPVCoordinates(state.getDate(), state.getFrame()).getPosition()
            inertToSpacecraft = StaticTransform.cast_(state.toTransform())
            sunInert = sun_pv.getPVCoordinates(state.getDate(), state.getFrame()).getPosition()
            sun_sat_vector = np.array(inertToSpacecraft.transformPosition(sunInert).normalize().toArray())
            sat_normal_vector = np.array(inertToSpacecraft.transformPosition(Vector3D.ZERO).normalize().toArray())
            dates.append(str(state.getAttitude().getDate()))
            eclipses.append(eclipse_detector.g(state) <= 0)
            satX.append(sat_normal_vector[0])
            satY.append(sat_normal_vector[1])
            satZ.append(sat_normal_vector[2])
            sunX.append(sun_sat_vector[0])
            sunY.append(sun_sat_vector[1])
            sunZ.append(sun_sat_vector[2])
            satpos.append(sat_position)
            sunpos.append(sun_position)

        d = {'Date': dates, 'Eclipse': eclipses, 'Sat X': satX, 'Sat Y': satY, 'Sat Z': satZ, 'Sun X': sunX,
             'Sun Y': sunY, 'Sun Z': sunZ}
        df = pd.DataFrame(data=d)

        return eclipses, df