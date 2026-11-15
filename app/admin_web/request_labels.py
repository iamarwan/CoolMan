"""English labels for the codes a build-a-sabil request carries."""

from app.models import RequestStatus

STATUS = {
    RequestStatus.new: "New",
    RequestStatus.contacted: "Contacted",
    RequestStatus.site_visit: "Site visit",
    RequestStatus.quoted: "Quoted",
    RequestStatus.won: "Won",
    RequestStatus.lost: "Lost",
}

LABELS: dict[str, dict[str, str]] = {
    "package": {
        "full": "Build a sabil (cooler, install, plaque, 1 year care)",
        "care_only": "Care plan for a cooler they already have",
        "company": "Company network (several coolers)",
    },
    "extras": {
        "filter": "Water filter",
        "shade": "Shade / cover",
        "cups": "Cup holder",
        "lighting": "Night light",
    },
    "timing": {
        "asap": "As soon as possible",
        "month": "Within a month",
        "quarter": "Within 3 months",
        "flexible": "No rush",
    },
    "purpose": {
        "memorial": "In memory of someone",
        "charity": "Ongoing charity",
        "business": "From a business",
        "community": "Mosque, school or community",
        "other": "Other",
    },
    "place_type": {
        "street": "Street / pavement",
        "mosque": "Mosque",
        "school": "School / university",
        "hospital": "Hospital / clinic",
        "shop": "Outside a shop",
        "workplace": "Workplace / factory",
        "other": "Other",
    },
    "permission": {
        "owner": "They own the place",
        "has_permission": "Has the owner's permission",
        "working_on_it": "Asking for permission",
        "not_yet": "No permission yet",
    },
    "yes_no": {"yes": "Yes", "no": "No", "unsure": "Not sure"},
    "contact_method": {"call": "Phone call", "whatsapp": "WhatsApp"},
    "best_time": {"morning": "Morning", "afternoon": "Afternoon", "evening": "Evening", "any": "Any time"},
    "governorate": {
        "cairo": "Cairo", "giza": "Giza", "alexandria": "Alexandria", "qalyubia": "Qalyubia",
        "sharqia": "Sharqia", "dakahlia": "Dakahlia", "gharbia": "Gharbia", "monufia": "Monufia",
        "beheira": "Beheira", "kafr_el_sheikh": "Kafr El Sheikh", "damietta": "Damietta",
        "port_said": "Port Said", "ismailia": "Ismailia", "suez": "Suez", "faiyum": "Faiyum",
        "beni_suef": "Beni Suef", "minya": "Minya", "asyut": "Asyut", "sohag": "Sohag",
        "qena": "Qena", "luxor": "Luxor", "aswan": "Aswan", "red_sea": "Red Sea",
        "new_valley": "New Valley", "matrouh": "Matrouh", "north_sinai": "North Sinai",
        "south_sinai": "South Sinai",
    },
}


def label(group: str, code: str | None) -> str:
    if not code:
        return "-"
    return LABELS.get(group, {}).get(code, code)


def extras_list(codes: str) -> list[str]:
    return [label("extras", c) for c in codes.split(",") if c]
