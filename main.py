from modules.user_interaction import UserInteraction


def main():
    dynamo_table_name = "PokemonTable"
    user_interaction = UserInteraction(dynamo_table_name)

    while True:
        if user_interaction.ask_user():
            user_interaction.draw_pokemon()
        else:
            print("Goodbye!")
            break


if __name__ == "__main__":
    main()
