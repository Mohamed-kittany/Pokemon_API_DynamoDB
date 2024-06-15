import boto3
from botocore.exceptions import ClientError
from .pokemon import Pokemon


class DynamoDB:
    def __init__(self, table_name, region_name='us-west-2'):
        """
        Initialize the DynamoDB class with the table name and region.

        :param table_name: Name of the DynamoDB table.
        :param region_name: AWS region where the DynamoDB table is located.
        """
        self.table_name = table_name
        self.dynamodb = boto3.resource('dynamodb', region_name=region_name)
        self.table = self.dynamodb.Table(table_name)


    def get_pokemon(self, pokemon_name):
        """
        Retrieve a Pokémon item from the DynamoDB table by its name.

        :param pokemon_name: Name of the Pokémon to retrieve.
        :return: A Pokemon object if found, None otherwise.
        """
        try:
            response = self.table.get_item(Key={'name': pokemon_name})
            item = response.get('Item', None)
            if item:
                # Unpack the item dictionary into the Pokemon class
                return Pokemon(**item)
            return None
        except ClientError as e:
            print(e.response['Error']['Message'])
            return None


    def save_pokemon(self, pokemon):
        """
        Save a Pokémon item to the DynamoDB table.

        :param pokemon: A Pokemon object to save.
        """
        try:
            self.table.put_item(Item=pokemon.to_dict())
        except ClientError as e:
            print(e.response['Error']['Message'])

