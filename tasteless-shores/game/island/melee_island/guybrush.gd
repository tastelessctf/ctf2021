extends "res://game/unit/npc.gd"


func _init().(Game.Unit.NPC, "Thrybrush Greepwood", 100.0):
	pass

func _ready():
	Server.enemies["player_31337"] = self

func chat(from, msg):
	if !(from.remote_id in players):
		return
	
	var bw = players[from.remote_id]
	var next_try = bw.dig()
	var insult = insults.keys()[next_try]
	if msg == insults[insult]:
		bw.distance -= 1
	else:
		bw.distance += 1

	if bw.distance <= 0:
		Server.spawn_chest(from, "FLAG_BIGWHOOP", Server.flags["FLAG_BIGWHOOP"].global_transform.origin)
		Server.chat(remote_id, from.remote_id, "you are faster than your shadow it seems!")
	else:
		Server.chat(remote_id, from.remote_id, insult)

func interact():
	Ui.ask("he speaks an ancient language...")

var insults = {
"You fight like a dairy Farmer!": "How appropriate. You fight like a cow!",
"This is the END for you, you gutter crawling cur!": "And I've got a little TIP for you, get the POINT?",
"I've spoken with apes more polite than you!": "I'm glad to hear you attended your family reunion!",
"Soon you'll be wearing my sword like a shish kebab!": "First you'd better stop waving it like a feather duster.",
"People fall at my feet when they see me coming!": "Even BEFORE they smell your breath?",
"I'm not going to take your insolence sitting down!": "Your hemorrhoids are flaring up again eh?",
"I once owned a dog that was smarter than you.": "He must have taught you everything you know.",
"Nobody's ever drawn blood from me and nobody ever will.": "You run THAT fast?",
"Have you stopped wearing diapers yet?": "Why? Did you want to borrow one?",
"There are no words for how disgusting you are.": "Yes there are. You just never learned them.",
"You make me want to puke.": "You make me think somebody already did.",
"My handkerchief will wipe up your blood!": "So you got that job as janitor, after all.",
"I got this scar on my face during a mighty struggle!": "I hope now you've learned to stop picking your nose.",
"I've heard you are a contemptible sneak.": "Too bad no one's ever heard of YOU at all.",
"You're no match for my brains, you poor fool.": "I'd be in real trouble if you ever used them.",
"You have the manners of a beggar.": "I wanted to make sure you'd feel comfortable with me.",
"I beat the Sword Master!": "Are you still wearing this lousy shirt?",
"Now I know what filth and stupidity really are.": "I'm glad to hear you attended your family reunion.",
"Every word you say to me is stupid.": "I wanted to make sure you'd feel comfortable with me.",
"I've got a long, sharp lesson for you to learn today.": "And I've got a little TIP for you. Get the POINT?",
"I will milk every drop of blood from your body!": "How appropriate, you fight like a cow!",
"I've got the courage and skill of a master swordsman.": "I'd be in real trouble if you ever used them.",
"My tongue is sharper than any sword.": "First, you'd better stop waving it like a feather-duster.",
"My name is feared in every dirty corner of this island!": "So you got that job as a janitor, after all.",
"My wisest enemies run away at the first sight of me!": "Even BEFORE they smell your breath?",
"Only once have I met such a coward!": "He must have taught you everything you know.",
"If your brother's like you, better to marry a pig.": "You make me think somebody already did.",
"No one will ever catch ME fighting as badly as you do.": "You run THAT fast?",
"My last fight ended with my hands covered with blood.": "I hope now you've learned to stop picking your nose.",
"I hope you have a boat ready for a quick escape.": "Why, did you want to borrow one?",
"My sword is famous all over the Caribbean!": "Too bad no one's ever heard of YOU at all.",
"You are a pain in the backside, sir!": "Your hemorrhoids are flaring up again, eh?",
"I usually see people like you passed-out on tavern floors.": "Even BEFORE they smell your breath?",
"There are no clever moves that can help you now.": "Yes there are. You just never learned them.",
"Every enemy I've met I've annihilated!": "With your breath, I'm sure they all suffocated.",
"You're as repulsive as a monkey in a negligee.": "I look THAT much like your fiancée?",
"Killing you would be justifiable homicide!": "Then killing you must be justifiable fungicide.",
"You're the ugliest monster ever created!":" If you don't count all the ones you've dated.",
"I'll skewer you like a sow at a buffet!": "When I'm done with you, you'll be a boneless filet.",
"Would you like to be buried, or cremated?": "With you around, I'd prefer to be fumigated.",
"Coming face to face with me must leave you petrified!": "Is that your face? I thought it was your backside.",
"When your father first saw you, he must have been mortified!": "At least mine can be identified.",
"You can't match my witty repartee!": "I could, if you would use some breath spray.",
"I have never seen such clumsy swordplay!": "You would have, but you were always running away.",
"En garde! Touché!	Your mother wears a toupee!": "My skills with a sword are highly venerated!	Too bad they're all fabricated.",
"I can't rest 'til you've been exterminated!": "Then perhaps you should switch to decaffeinated.",
"I'll leave you devastated, mutilated, and perforated!": "Your odor alone makes me aggravated, agitated, and infuriated.",
"Heaven preserve me! You look like something that's died!": "The only way you'll be preserved is in formaldehyde.",
"I'll hound you night and day!": "Then be a good dog. Sit! Stay!",
"My attacks have left entire islands depopulated!": "With your breath, I'm sure they all suffocated.",
"You have the sex appeal of a Shar-Pei.": "I look THAT much like your fiancée?",
"When I'm done, your body will be rotted and putrified!": "Then killing you must be justifiable fungicide.",
"Your looks would make pigs nauseated.": "If you don't count all the ones you've dated.",
"Your lips look like they belong on catch of the day!": "When I'm done with you, you'll be a boneless filet.",
"I give you a choice. You can be gutted, or decapitated!": "With you around, I'd prefer to be fumigated.",
"Never before have I seen someone so sissified!": "Is that your face? I thought it was your backside.",
"You're a disgrace to your species, you're so undignified!": "At least mine can be identified.",
"Nothing can stop me from blowing you away!": "I could, if you would use some breath spray.",
"I have never lost to a melee!": "You would have, but you were always running away.",
"Your mother wears a toupee!": "Oh, that is so cliché.",
"My skills with a sword are highly venerated!": "Too bad they're all fabricated.",
"Your stench would make an outhouse cleaner irritated!": "Then perhaps you should switch to decaffeinated.",
"I can't tell you which of my traits leaves you most intimidated.": "Your odor alone makes me aggravated, agitated, and infuriated.",
"Nothing on this Earth can save your sorry hide!": "The only way you'll be preserved is in formaldehyde.",
"You'll find I am dogged and relentless to my prey!": "Then be a good dog. Sit! Stay!",
}

var players = {}

class BigWhoop:
	var pos = Vector3.ZERO
	var rotation = 0 as int
	var distance = 10 as int

	func _init():
		pos.x = randi() % 255
		pos.y = randi() % 255
		pos.z = randi() % 255

	func dig():
		var hint = (int(pos.x) ^ ((int(pos.x) << 4)) & 0xff) & 0xff
		pos.x = pos.y
		pos.y = pos.z
		pos.z = rotation
		rotation = int(pos.z) ^ hint ^ (int(pos.z) >> 1) ^ ((int(hint) << 1) & 0xff)
		return rotation % 64

func _on_Area_body_entered(body: Node):
	if Server.socket != null:
		players[body.remote_id] = BigWhoop.new()

func _on_Area_body_exited(body: Node):
	if Server.socket != null:
		players.erase(body.remote_id)
