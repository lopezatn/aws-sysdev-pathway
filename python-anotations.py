# How to loop through JSON from EC2
for reservation in response.get("Reservations", []):
    for instance in reservation.get("Instances", []):
        for tag in instance.get("Tags", []):
            if tag["Key"] == "Name":
                print(tag["Value"])





# NOTES:
# Dict = one thing with named parts. List = many things of the same kind. Looping is only required when you see [list] in the structure.
# .get() → “look up a key in one dictionary.”
user = {"name": "Agus", "age": 27}
user.get("name", "none") 
# next() → “find the first match in a list (or generator).”
next((t["Value"] for t in instance.get("Tags", []) if t["Key"] == "Name"), "—")