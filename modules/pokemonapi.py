import requests
from modules.pokemon import Pokemon


class PokemonAPI:
    BASE_URL = "https://pokeapi.co/api/v2/"  # Base URL for the PokeAPI

    @staticmethod
    def get_pokemon_list(limit=100):
        """
        Retrieve a list of Pokémon names from the PokeAPI.

        This static method sends a GET request to the PokeAPI to fetch a list of Pokémon names.
        The method raises an HTTPError if the request fails.

        :param limit: The number of Pokémon to retrieve (default is 100).
        :return: A list of dictionaries containing Pokémon names and URLs.
        """
        response = requests.get(f"{PokemonAPI.BASE_URL}pokemon?limit={limit}")
        response.raise_for_status()  # Raise an exception for HTTP errors
        return response.json()['results']  # Extract and return the list of Pokémon

    @staticmethod
    def get_pokemon_details(pokemon_name):
        """
        Retrieve detailed information about a specific Pokémon from the PokeAPI.

        This static method sends a GET request to the PokeAPI to fetch details of a specific Pokémon by name.
        The method raises an HTTPError if the request fails.

        :param pokemon_name: The name of the Pokémon to retrieve details for.
        :return: A Pokemon object initialized with the API data.
        """
        response = requests.get(f"{PokemonAPI.BASE_URL}pokemon/{pokemon_name}")
        response.raise_for_status()  # Raise an exception for HTTP errors
        return Pokemon.from_api_data(response.json())  # Create and return a Pokemon instance
