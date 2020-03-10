from sqlalchemy import create_engine
from models import DeclarativeBase
import os

user = os.environ['USER']
password = os.environ['PASSWORD']
postgres_host = os.environ['POSTGRES_HOST']
postgres_port = os.environ['POSTGRES_PORT']
vassar_db_name = 'vassar'

db_string = f'postgresql+psycopg2://{user}:{password}@{postgres_host}:{postgres_port}/{vassar_db_name}'

def db_connect():
    print("Creating database engine")
    print(db_string)
    return create_engine(db_string, echo=True)

def run():
    print("Run")
    engine = db_connect()
    conn = engine.connect()
    print("Connection:", conn)
    conn.close()

    print("Engine:", engine)









if __name__ == "__main__":
    run()
