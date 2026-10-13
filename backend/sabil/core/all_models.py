# core/all_models.py
#
# SQLAlchemy only knows about a table once its model class has been imported.
# Models refer to each other by name (e.g. relationship("WaterCooler")), so ALL
# of them must be imported before the first query. Importing this one file does
# exactly that. If you add a new model file, add it here.

from sabil.users.models import User  # noqa: F401
from sabil.sponsors.models import Sponsor, SponsorType  # noqa: F401
from sabil.coolers.models import (  # noqa: F401
    WaterCooler,
    CoolerPhoto,
    CoolerStatus,
    CupsType,
    PhotoCategory,
)
