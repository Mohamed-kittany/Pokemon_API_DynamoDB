from modules.user_interaction import UserInteraction


def main():
    dynamo_table_name = "PokemonTable"
    user_interaction = UserInteraction(dynamo_table_name)

    while True:
        user_response = input("Would you like to draw a Pokémon? (yes/no): ").strip().lower()
        if user_response == 'yes':
            user_interaction.draw_pokemon()
        elif user_response == 'no':
            print("Goodbye!")
            break
        else:
            print("Please enter 'yes' or 'no'.")


if __name__ == "__main__":
    main()
