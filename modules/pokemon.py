class Pokemon:
    def __init__(self, id, name, weight, image):
        self.id = id
        self.name = name
        self.weight = weight
        self.image = image


    @classmethod
    def from_api_data(cls, data):
        """
        Create a Pokemon instance from API data.

        This method is defined as a class method using the @classmethod decorator so that it can be called on the class itself,
        rather than on instances of the class. The cls keyword is used to refer to the class itself, allowing us to create
        a new instance of the class using the class constructor.

        :param data: Dictionary containing Pokémon data from the API.
        :return: A Pokemon object initialized with the API data.
        """
        return cls(
            id=data["id"],
            name=data["name"],
            weight=data["weight"],
            image=data["sprites"]["front_default"]
        )


    def to_dict(self):
        """
        Convert the Pokemon object to a dictionary format suitable for DynamoDB.

        :return: A dictionary representation of the Pokemon object.
        """
        return {
            "id": self.id,
            "name": self.name,
            "weight": self.weight,
            "image": self.image
        }

