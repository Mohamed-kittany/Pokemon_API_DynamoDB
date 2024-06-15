import random
from .pokemonapi import PokemonAPI
from .dynamodb import DynamoDB


class UserInteraction:
    def __init__(self, dynamo_table_name):
        """
        Initialize the UserInteraction class with the given DynamoDB table name.

        :param dynamo_table_name: The name of the DynamoDB table to interact with.
        """
        self.dynamo = DynamoDB(dynamo_table_name)

    def ask_user(self):
        """
        Prompt the user to decide if they want to draw a Pokémon.

        :return: True if the user wants to draw a Pokémon, False otherwise.
        """
        return input("Would you like to draw a Pokémon? (yes/no): ").strip().lower() == 'yes'

    def draw_pokemon(self):
        """
        Draw a random Pokémon from the PokeAPI and handle its details.

        This method retrieves a list of Pokémon, selects one at random, and checks if it is already in the DynamoDB table.
        If the Pokémon is found in the database, its details are displayed. Otherwise, it fetches the details from the API,
        saves them to the database, and then displays the details.
        """
        # Retrieve a list of Pokémon names from the PokeAPI
        pokemon_list = PokemonAPI.get_pokemon_list()
        # Select a random Pokémon from the list
        random_pokemon = random.choice(pokemon_list)
        pokemon_name = random_pokemon['name']
        # Check if the Pokémon is already in the DynamoDB table
        pokemon = self.dynamo.get_pokemon(pokemon_name)
        if pokemon:
            print(f"Pokémon {pokemon_name} is already in the database.")
            self.display_pokemon(pokemon)
        else:
            # Retrieve detailed information about the Pokémon from the PokeAPI
            pokemon_details = PokemonAPI.get_pokemon_details(pokemon_name)
            # Save the Pokémon details to the DynamoDB table
            self.dynamo.save_pokemon(pokemon_details)
            print(f"Pokémon {pokemon_name} has been added to the database.")
            self.display_pokemon(pokemon_details)

    @staticmethod
    def display_pokemon(pokemon):
        """
        Display the details of a Pokémon.

        :param pokemon: A Pokemon object containing the details to display.
        """
        print(f"Name: {pokemon.name}")
        print(f"ID: {pokemon.id}")
        print(f"Weight: {pokemon.weight}")
        print(f"Image: {pokemon.image}")
