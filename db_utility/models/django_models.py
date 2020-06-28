from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean, UniqueConstraint
from sqlalchemy.orm import relationship
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL

from sqlalchemy.schema import DropTable
from sqlalchemy.ext.compiler import compiles

import os
import pandas as pd


# @compiles(DropTable, "postgresql")
# def _compile_drop_table(element, compiler, **kwargs):
#     return compiler.visit_drop_table(element) + " CASCADE"


# UserInformation
class auth_user(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'auth_user'
    __table_args__ = {'autoload': True}
    # id = Column(Integer, primary_key=True)

    # session_id = Column('session_id', String, ForeignKey('django_session.session_key'))

    # user_id = Column('user_id', Integer, ForeignKey('auth_user.id'))

    # UniqueConstraint('user_id', 'session_id')

    # daphne_version = Column('daphne_version', String)

    # channel_name = Column('channel_name', String)

    

# class django_session(DeclarativeBase):
#     """Sqlalchemy broad measurement categories model"""
#     __tablename__ = 'django_session'
#     session_key = Column(String, primary_key=True)

#     session_data = Column('session_data', String)

#     expire_date = Column('expire_date', DateTime)



# class auth_user(DeclarativeBase):
#     """Sqlalchemy broad measurement categories model"""
#     __tablename__ = 'auth_user'
#     id = Column(Integer, primary_key=True)

#     password = Column('password', String)

#     last_login = Column('last_login', DateTime)

#     is_superuser = Column('is_superuser', Boolean)

#     username = Column('username', String, unique=True)

#     first_name = Column('first_name', String)

#     last_name = Column('last_name', String)

#     email = Column('email', String)

#     is_staff = Column('is_staff', Boolean)

#     is_active = Column('is_active', Boolean)

#     date_joined = Column('date_joined', DateTime)