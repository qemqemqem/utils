from collections import defaultdict
from typing import List, Optional, Dict
import re

def get_list_from_response(response: str) -> List[str]:
    list_items = []
    for l in response.split("\n"):
        if l.startswith("-") or l.startswith("*") or l.startswith("+") or l.startswith("•"):
            list_items.append(l[1:].strip())
        # Match numbered lists
        elif re.match(r"^\d+\.", l):
            list_items.append(l[l.index(".") + 1:].strip())
        elif re.match(r"^\d+\)", l):
            list_items.append(l[l.index(")") + 1:].strip())
    return list_items

def get_dict_of_lists_from_response(response: str, headers: List[str]) -> Dict[str, List[str]]:
    lists = {header: [] for header in headers}
    current_header = headers[0]
    for l in response.split("\n"):
        found: Optional[str] = None
        if l.startswith("#"):
            for header in headers:
                if header.lower() in l.lower():
                    current_header = header
                    break
        if l.startswith("-") or l.startswith("*") or l.startswith("+") or l.startswith("•"):
            found = l[1:].strip()
        # Match numbered lists
        elif re.match(r"^\d+\.", l):
            found = l[l.index(".") + 1:].strip()
        elif re.match(r"^\d+\)", l):
            found = l[l.index(")") + 1:].strip()
        else:
            # It's not a list element. Check if it's a header again.
            for header in headers:
                if header.lower() in l.lower():
                    current_header = header
                    break

        if found is not None:
            lists[current_header].append(found)

    any_empty = any(len(lists[header]) == 0 for header in headers)
    if any_empty:
        print(f"Couldn't find any lists with headers {headers} in response:\n{response}")
        # raise ValueError(f"Couldn't find any lists with headers {headers} in response:\n{response}")

    return lists
