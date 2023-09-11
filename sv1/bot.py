import discord
import discord.app_commands
import subprocess
import time
import random
from dotenv import load_dotenv
import os

load_dotenv()

client = discord.Client(intents=discord.Intents.default())
Token = os.environ.get("Bot_Token")
tree = discord.app_commands.CommandTree(client)


dm_warn = discord.Embed(title="WARN",description="このコマンドは外部では使えません！",color=0xff0000)


def Call(command):

    cmd = command.split(" ")

    code = subprocess.call(cmd,shell=True)

    return code


def Check_output(command):

    cmd = command.split(" ")

    result = subprocess.check_output(cmd,shell=True)

    return result


def Boot():

    code = Call("start sv1.exe +server_dir C:/Stormworks_server/sv1/server_config/")

    return code


def Stop():

    code = Call("taskkill /f /im sv1.exe")

    return code


def Reboot():

    Stop()

    code = Boot()

    return code


async def Update():

    code = Call("cd ../steamcmd & C:/Stormworks_server/steamcmd/sv1_update.bat")

    return code



def Status():

    output = Check_output("C:/Stormworks_server/module/process_check.bat sv1.exe")

    result = output.decode("utf-8").strip()

    if result == "true":
        
        return True
    
    else:

        return False




@tree.command(
    name="boot",
    description="サーバーを起動します。",
)

async def boot(interaction:discord.Interaction):

    if interaction.guild_id == 1012990607247036446 or interaction.user.id == 743426113027440680:

        result = Status()

        if result == True:

            embed = discord.Embed(title="INFO",description="サーバーは稼働中です。",color=0x0000ff)
        
        else:
            code = Boot()

            if code == 0:

                embed = discord.Embed(title="INFO",description="サーバーを起動しました。",color=0x00ff00)
            
            else:

                embed = discord.Embed(title="INFO",description="サーバーの起動に失敗しました",color=0xff0000)
    
    else:

        embed = dm_warn
    
    await interaction.response.send_message(embed=embed)


@tree.command(
    name="down",
    description="サーバーを停止します。"
)
async def down(interaction:discord.Interaction):

    if interaction.guild_id == 1012990607247036446 or interaction.user.id == 743426113027440680:

        code = Stop()

        if code == 0:

            embed = discord.Embed(title="INFO",description="サーバーを停止しました。",color=0x00ff00)

        else:

            embed = discord.Embed(title="INFO",description="サーバーは稼働していません。",color=0xff0000)
        
    else:

        embed = dm_warn
    
    await interaction.response.send_message(embed=embed)


@tree.command(
    name="reboot",
    description="サーバーを再起動します。"
)
async def reboot(interaction:discord.Interaction):

    if interaction.guild_id == 1012990607247036446 or interaction.user.id == 743426113027440680:
    
        code = Reboot()

        if code == 0:

            embed = discord.Embed(title="INFO",description="サーバーを再起動しました。",color=0x00ff00)
        
        else:

            embed = discord.Embed(title="INFO",description="サーバーの再起動に失敗しました。",color=0xff0000)
    
    else:

        embed = dm_warn
    
    await interaction.response.send_message(embed=embed)



@tree.command(
    name="status",
    description="サーバーの状態を表示します。"
)
async def status(interaction:discord.Interaction):   

    if interaction.guild_id == 1012990607247036446 or interaction.user.id == 743426113027440680:

        result = Status()

        if result == True:

            embed = discord.Embed(title="INFO",description="サーバーは稼働しています。",color=0x00ff00)

        else:

            embed = discord.Embed(title="INFO",description="サーバーは停止しています。",color=0xff0000)

    else:

        embed = dm_warn

    await interaction.response.send_message(embed=embed)

@tree.command(
    name = "update",
    description="サーバーを更新します。実行するとサーバーが再起動されます。"
)
async def update(interaction:discord.Interaction):

    if interaction.guild_id == 1012990607247036446 or interaction.user.id == 743426113027440680:

        await interaction.response.defer()

        Stop()

        code = await Update()

        if code == 0:

            code = Call("where server64.exe")

            if code == 0:

                Call("del sv1.exe")
                Call("rename server64.exe sv1.exe")

                code = Boot()

                if code == 0:

                    embed = discord.Embed(title="INFO",description="正常に更新を完了しました。",color=0x00ff00)
                
                else:
                    embed = discord.Embed(title="INFO",description="サーバーの起動に失敗しました。",color=0x0000ff)
            
            else:
                embed = discord.Embed(title="INFO",description="サーバーは既に最新版です。",color=0x00ff00)
        
        else:
            embed = discord.Embed(title="INFO",description=f"サーバーの更新に失敗しました。終了コード：{code}",color=0xff0000)
        
        await interaction.followup.send(embed=embed)
    
    else:

        embed = dm_warn

        await interaction.response.send_message(embed=embed)


@tree.command(
    name="omikuji",
    description="おみくじが引けます。"
)
async def omikuji(interaction:discord.Interaction):

    kuji = []
    base = {"超大吉":1,"大吉":5,"吉":15,"中吉":20,"小吉":20,"末吉":15,"凶":10,"大凶":5,"犬吉":3,"無":2,"芋吉":2,"超大凶":1,"草":1}

    for key,value in base.items():

        for i in range(value):

            kuji.append(key)
    
    index = random.randint(1,len(kuji))-1

    await interaction.response.send_message(kuji[index])

@tree.command(
    name="help",
    description="ヘルプを表示します。"
)
async def help(interaction:discord.Interaction):

    if interaction.guild_id == 1012990607247036446 or interaction.user.id == 743426113027440680:

        embed = discord.Embed(title="HELP",description="コマンドのヘルプです。",color=0x0000ff)

        embed.add_field(name="/up",value="サーバーを起動します。",inline=False)
        embed.add_field(name="/down",value="サーバーを停止します。",inline=False)
        embed.add_field(name="/reboot",value="サーバーを再起動します。",inline=False)
        embed.add_field(name="/status",value="サーバーの状態を表示します。",inline=False)
        embed.add_field(name="/update",value="サーバーを更新します。実行するとサーバーが再起動されます。",inline=False)
        embed.add_field(name="/help",value="このヘルプを表示します。",inline=False)
    
    else:
        
        embed=dm_warn

    await interaction.response.send_message(embed=embed)

@client.event
async def on_ready():
    print("Discord.py Version:"+discord.__version__)
    print(f"{client.user} にログインしました")
    await tree.sync()

client.run(Token)