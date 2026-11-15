"""Story, crew, professions, dialogue and mission metadata."""

PROFESSIONS = [
 ("astronaut", "Astronaut", "#7ec8ff", "Walks, flies, and flips the switches.",
  "Plan routes, run launch switchboards, and time burns.", ["Route map", "Switchboard", "Burn timer"]),
 ("engineer", "Engineer", "#ffb347", "Builds it and fixes it.",
  "Assemble parts in order, inspect hardware, and find the failed part.", ["Assembly rack", "Gauges", "Repair manual"]),
 ("physicist", "Physicist", "#b39bff", "Turns forces into numbers.",
  "Compute thrust, impulse, and motion from simple physics.", ["Calculator", "Sensor log", "Timing bar"]),
 ("mathematician", "Mathematician", "#6fe0c1", "Keeps the numbers honest.",
  "Work out fuel, timing, and power budgets with reserves.", ["Calculator", "Data tables", "Budget sheet"]),
 ("biologist", "Biologist", "#8de36f", "Keeps samples clean and living things safe.",
  "Follow clean-handling steps and read microscope views.", ["Sterile kit", "Microscope", "ID cards"]),
 ("medical", "Medical Officer", "#ff7b8a", "Looks after the crew.",
  "Scan vitals, find the one who needs help, and choose the calm fix.", ["Scanner", "Vitals board", "Treatment kit"]),
 ("comms", "Communications Lead", "#ffd95e", "Keeps the voices of the mission connected.",
  "Tune radios, decode messages, and write short, honest reports.", ["Radio dial", "Cipher wheel", "Message pad"]),
 ("director", "Flight Director", "#f2f2f2", "Makes the call.",
  "Prioritize alerts and decide go or no-go with the whole team.", ["Alert board", "Roll call", "Decision log"]),
]

CREW = [
 ("mira_vale", "Mira Vale", "director", "Flight Director. Calm voice of mission control."),
 ("samira_shah", "Samira Shah", "astronaut", "Commander. Flew every simulator twice."),
 ("alex_rivera", "Alex Rivera", "engineer", "Flight Engineer. Can hear a loose bolt."),
 ("ingrid_solheim", "Dr. Ingrid Solheim", "physicist", "Physicist. Loves a good graph."),
 ("dev_malhotra", "Dev Malhotra", "mathematician", "Mission Mathematician. Checks every sum twice."),
 ("amara_okonkwo", "Dr. Amara Okonkwo", "biologist", "Biologist. Never forgets her gloves."),
 ("leo_marchetti", "Dr. Leo Marchetti", "medical", "Flight Surgeon. Always has a snack ready."),
 ("yuki_tanaka", "Yuki Tanaka", "comms", "Communications Lead. Lives on headset."),
]

COLOR = {p[0]: p[2] for p in PROFESSIONS}
CREW_OF = {c[2]: c[0] for c in CREW}

ACHIEVEMENTS = [
 ("first_shift", "First Shift", "Finish your first mission.", "Complete any mission."),
 ("clean_sheet", "Clean Sheet", "Finish a mission with no mistakes, no help, and no recovery.", "Be careful and be clear."),
 ("steady_hands", "Steady Hands", "Recover from an emergency without help.", "Fix it yourself after a problem."),
 ("classified", "Classified", "Log the strange signal as unknown and keep to the facts.", "Do not guess in 2026."),
 ("frontier", "Frontier", "Finish the whole 2026 campaign.", "Complete all five 2026 missions."),
 ("verified", "Verified", "Reject a wrong AI answer.", "Check the helper before you trust it."),
 ("first_contact", "First Contact", "Follow protocol when the signal is heard.", "Wait for the committee."),
 ("long_listen", "The Long Listen", "Finish the epilogue.", "Be patient."),
 ("cross_train", "Cross Training", "Play three different professions.", "Try a new role."),
]

YEARS = [
 (2026, "Genesis Year", "The First Crew",
  ("manual_diagnostics_2026", "Manual Diagnostics", "Check the numbers by hand before you trust a screen.",
   "Every task asks you to show your work."),
  ["genesis", "countdown", "transit", "red_horizon", "new_beginnings"]),
 (2027, "Relay Year", "Moon Relay",
  ("ai_assist_2027", "AI Assistant, Verified", "A helper suggests answers. People check them.",
   "AI suggestions appear on tasks. Always verify them."),
  ["shackleton_relay"]),
 (2028, "Drive Year", "Propulsion Research",
  ("ion_drive_2028", "Ember Drive", "A new engine pushes softly for a very long time.",
   "Propulsion tasks use real thrust and exhaust speed numbers."),
  ["ember_drive"]),
 (2029, "Sensor Year", "Living Habitat",
  ("biosensors_2029", "Living Sensors", "Sensors made from living cells watch the habitat.",
   "Wearable and wall sensors show live readings."),
  ["living_sensors"]),
 (2030, "Listening Year", "The Signal Protocol",
  ("deep_listening_2030", "Deep Listening Array", "A giant array listens for faint signals.",
   "Signal tasks follow a strict verification protocol."),
  ["first_light"]),
 (2031, "Beyond Year", "Beyond Humanity",
  ("array_extension_2031", "Array Extension", "More dishes, more patience.",
   "The array grows. The reply is still on its way."),
  ["long_listen"]),
]

# id: (title, room name, bg color, duty_text, optional text, optional station, optional fact, learn[2], team notes)
MISSIONS = {
 "genesis": ("Project Genesis", "Assembly Hangar", "#1b2a41",
   "Finish your station duty for the build shift.", "Read the wall chart of safe walking lanes.", "Wall Chart",
   "Painted walking lanes keep tools and people out of each other's way.",
   ["Checklists catch mistakes before they grow.", "Safe teams double-check each other."]),
 "countdown": ("Countdown", "Launch Control and Pad Gallery", "#2b2140",
   "Finish your station duty for the launch.", "Look at the pad camera feed.", "Pad Camera",
   "The pad is cleared of people long before the countdown ends.",
   ["A HOLD call is part of doing the job well.", "Everyone reports from their own station."]),
 "transit": ("Long Transit", "Spacecraft Corridor", "#22313f",
   "Finish your station duty for the transit shift.", "Check the star map on the wall.", "Star Map",
   "On a long trip small corrections early save a lot of fuel later.",
   ["Radio takes minutes to cross the gap to Earth.", "Small hums and drifts tell big stories."]),
 "red_horizon": ("Red Horizon", "Mars Surface", "#4a2a20",
   "Finish your station duty on the surface.", "Read the surface weather sign.", "Weather Sign",
   "Mars has thin air. Dust storms can last for weeks.",
   ["Mars pulls less than Earth, but landing still needs care.", "Equipment goes down before people rest."]),
 "new_beginnings": ("New Beginnings", "Outpost Site", "#2a2f3a",
   "Finish your station duty at the outpost.", "Read the outpost log board.", "Log Board",
   "Good scientists write down what they saw, not what they hoped.",
   ["A strange signal is data first.", "Do not claim more than the evidence shows."]),
 "shackleton_relay": ("Shackleton Relay", "Lunar Relay Station", "#202430",
   "Finish your station duty at the relay.", "Read the crater rim map.", "Rim Map",
   "Shackleton crater has sunlit rims and dark, very cold floors.",
   ["AI helpers can be wrong, so check them.", "Verifying is a skill, not a delay."]),
 "ember_drive": ("Ember Drive", "Propulsion Hall", "#2e2430",
   "Finish your station duty in the hall.", "Study the thruster poster.", "Thruster Poster",
   "Ion engines make small pushes that add up over months.",
   ["Higher exhaust speed means less fuel for the same push.", "Heat limits are safety limits."]),
 "living_sensors": ("Living Sensors", "Habitat Garden Dome", "#1f3a2c",
   "Finish your station duty in the dome.", "Read the plant growth board.", "Growth Board",
   "Plants and sensors share the dome air. Both need steady readings.",
   ["A reading is only as good as its calibration.", "Odd numbers deserve a second check."]),
 "first_light": ("First Light", "Deep Listening Array", "#1a2238",
   "Finish your station duty at the array.", "Read the protocol card.", "Protocol Card",
   "The protocol card says: verify first, answer later, and tell everyone together.",
   ["Patterns can be natural or made. Check carefully.", "A reply is a long promise, so follow protocol."]),
 "long_listen": ("Beyond Humanity", "Array Overlook", "#14182b",
   "Finish your station duty at the overlook.", "Look through the telescope.", "Telescope",
   "Light from the nearest stars left years before you looked up.",
   ["Light takes years to cross space.", "Patience is a team skill."]),
}

TEAM_NOTES = {
 "genesis": [("mira_vale", "Everyone checked someone else's work today."), ("samira_shah", "The capsule looks ready."), ("alex_rivera", "The stack went together clean.")],
 "countdown": [("mira_vale", "Every station called it clearly."), ("yuki_tanaka", "The net stayed clear."), ("leo_marchetti", "Crew vitals looked calm.")],
 "transit": [("mira_vale", "The ship stays on course."), ("amara_okonkwo", "The water loop is under control."), ("dev_malhotra", "The numbers add up.")],
 "red_horizon": [("mira_vale", "Boots, wheels, and dishes are down."), ("ingrid_solheim", "The landing numbers held."), ("samira_shah", "The mast is up.")],
 "new_beginnings": [("mira_vale", "We logged what we saw and nothing more."), ("yuki_tanaka", "The raw data is on its way to Earth."), ("amara_okonkwo", "The rover sample is a mineral, not a cell.")],
 "shackleton_relay": [("mira_vale", "Checking the helper was the right call."), ("dev_malhotra", "A good sum beats a fast sum."), ("alex_rivera", "The relay is humming.")],
 "ember_drive": [("mira_vale", "A slow engine, a steady team."), ("ingrid_solheim", "The thrust numbers matched."), ("alex_rivera", "Cooling held steady.")],
 "living_sensors": [("mira_vale", "The dome is watching itself."), ("amara_okonkwo", "The living sensors are glowing."), ("leo_marchetti", "Wearables and hands agreed.")],
 "first_light": [("mira_vale", "We followed protocol."), ("yuki_tanaka", "Everything is logged."), ("dev_malhotra", "The pattern is clean.")],
 "long_listen": [("mira_vale", "We are still listening."), ("ingrid_solheim", "Light is still on its way."), ("samira_shah", "It is a good view.")],
}

TALKS = {
 "genesis": {
  "mira_vale": "Check your own step, then check a neighbor's. That is the whole secret.",
  "samira_shah": "I will fly in this capsule one day. Build it like it matters.",
  "alex_rivera": "Parts go in bottom to top. The stack remembers every shortcut.",
  "ingrid_solheim": "Push times time gives you impulse. I will show you after lunch.",
  "dev_malhotra": "Always carry extra fuel. The plan is never the whole story.",
  "amara_okonkwo": "Gloves first, always. Germs love a rushed scientist.",
  "leo_marchetti": "If you feel off, say so. I would rather be bored than late.",
  "yuki_tanaka": "Radio check is the first thing and the last thing."},
 "countdown": {
  "mira_vale": "A HOLD is not a failure. It is the team doing its job.",
  "samira_shah": "My heart is doing a drum solo. That is normal, right?",
  "alex_rivera": "Every clamp is tight or it is not. There is no almost.",
  "ingrid_solheim": "The rocket needs more thrust than weight. We have it, and a little extra.",
  "dev_malhotra": "The window opens at 06:40. The weather decides if we use it.",
  "amara_okonkwo": "The sample lockers are sealed and tagged. They will ride quietly.",
  "leo_marchetti": "Crew vitals look steady. Big feelings, small problems.",
  "yuki_tanaka": "Every channel is on the net. Say GO only if you mean it."},
 "transit": {
  "mira_vale": "Earth is minutes away by radio now. Think before you speak.",
  "samira_shah": "I never get tired of the window. Same stars, bigger quiet.",
  "alex_rivera": "A new hum is a new story. I like to hear it early.",
  "ingrid_solheim": "A mass on a spring tells you its weight, even floating.",
  "dev_malhotra": "More speed needs a lot more fuel. The rocket equation is stern.",
  "amara_okonkwo": "The water loop grows microbes. Swabs keep them honest.",
  "leo_marchetti": "Headache and stale air go together. Check the scrubber first.",
  "yuki_tanaka": "Keep messages short. Every letter costs us time."},
 "red_horizon": {
  "mira_vale": "Equipment first, rest second. In that order.",
  "samira_shah": "The sky is butterscotch. Nobody told me.",
  "alex_rivera": "Winch lines pull evenly or the mast leans. I check all five.",
  "ingrid_solheim": "Mars pulls less than Earth. Falling is slower but still not gentle.",
  "dev_malhotra": "The landing ellipse is smaller than the field next to my old school.",
  "amara_okonkwo": "I will sterilize the scoop twice. The soil deserves a fair test.",
  "leo_marchetti": "Dusty cough is not a decompression alarm. Check the gauge.",
  "yuki_tanaka": "Dust makes the radio hiss. A filter is your friend."},
 "new_beginnings": {
  "mira_vale": "We follow the data. Not the headlines, not the hopes.",
  "samira_shah": "I am proud to stand on a place that looked so far away.",
  "alex_rivera": "Flickering lights are a connector until proven otherwise.",
  "ingrid_solheim": "A solar panel loves the sun straight on. Tilt it and it sulks.",
  "dev_malhotra": "Add every load, then check the supply. Margins keep us warm.",
  "amara_okonkwo": "The rover sample is a crystal, not a creature. That is still wonderful.",
  "leo_marchetti": "Tired crew miss alarms. Swap shifts before it is a problem.",
  "yuki_tanaka": "The pulses were odd. I logged them exactly as I heard them."},
 "shackleton_relay": {
  "mira_vale": "Use the helper like a colleague. Colleagues can be wrong.",
  "samira_shah": "The rim is bright and the floor is black. It is a strange place to walk.",
  "alex_rivera": "Cold stiffens everything. A heater pad is a small hero.",
  "ingrid_solheim": "Mass stays the same on the Moon. Weight is the part that changes.",
  "dev_malhotra": "Efficiency is how much light becomes power. Ask the helper to show its work.",
  "amara_okonkwo": "Closed habitats grow microbes on every wall. Swab on a schedule.",
  "leo_marchetti": "Badges add up radiation. Step into the shielded room if one climbs.",
  "yuki_tanaka": "The Moon is about a second away by radio. A short lag, but it counts."},
 "ember_drive": {
  "mira_vale": "A slow engine needs a patient team.",
  "samira_shah": "Gentle push for months. I like it.",
  "alex_rivera": "Cool the nozzle or it will cook the grid.",
  "ingrid_solheim": "Tiny mass, huge speed, steady push.",
  "dev_malhotra": "High Isp means less fuel for the same push.",
  "amara_okonkwo": "Warm water grows film. The coolant loop needs a swab.",
  "leo_marchetti": "Stand slowly after a burn. Your blood needs a moment.",
  "yuki_tanaka": "A notch filter cuts out the engine whine."},
 "living_sensors": {
  "mira_vale": "The dome watches itself, and we watch the dome.",
  "samira_shah": "Put the nodes where the air really moves.",
  "alex_rivera": "A node with low voltage lies politely. Check every mount.",
  "ingrid_solheim": "Voltage in, percent out. Calibrate once, check often.",
  "dev_malhotra": "Two points make a line. A third point proves it.",
  "amara_okonkwo": "Some of our sensors are living cells that glow. Handle with care.",
  "leo_marchetti": "Watches can be wrong. Check by hand if a number looks odd.",
  "yuki_tanaka": "Sensor streams are only as good as their weakest channel."},
 "first_light": {
  "mira_vale": "Verify first. Answer later. Tell everyone together.",
  "samira_shah": "I just want to be sure we do this the careful way.",
  "alex_rivera": "A cold amplifier is a quiet amplifier. Quiet is good.",
  "ingrid_solheim": "Natural sources repeat. This one changes. That is worth checking, not shouting about.",
  "dev_malhotra": "Prime numbers are a clean pattern. They are a good greeting.",
  "amara_okonkwo": "I will keep the cooling loop clean. Dirty loops hiss.",
  "leo_marchetti": "Long watches wear people down. Rest before the big call.",
  "yuki_tanaka": "Light from 4.2 years away needs 8.4 years for an answer. That is a long promise."},
 "long_listen": {
  "mira_vale": "We did the careful thing. Now we wait.",
  "samira_shah": "I look up more than I used to.",
  "alex_rivera": "Dishes line up like a choir. All must hum the same note.",
  "ingrid_solheim": "Light is slow when the distance is big.",
  "dev_malhotra": "Four dishes catch four times as much. It still might be silence.",
  "amara_okonkwo": "The dome garden is thriving. Life is a quiet thing.",
  "leo_marchetti": "Waiting is hard. Walk, sleep, and talk it out.",
  "yuki_tanaka": "I listen every day. Even silence tells us something."},
}

EMERGENCY_LINES = {
 "genesis": ("alex_rivera", "Hold on. Take a breath and run the step again, nice and slow."),
 "countdown": ("yuki_tanaka", "Stay on the net. We fix it and call again."),
 "transit": ("samira_shah", "No panic. We have time. Do it again."),
 "red_horizon": ("samira_shah", "Eyes up. Redo it and keep the dust out."),
 "new_beginnings": ("yuki_tanaka", "We are not in a hurry. Let us do it right."),
 "shackleton_relay": ("dev_malhotra", "Check the claim, then check it again."),
 "ember_drive": ("ingrid_solheim", "Cool heads. Recompute and retry."),
 "living_sensors": ("amara_okonkwo", "Calm hands. Retry the step."),
 "first_light": ("yuki_tanaka", "Stop the reply. Follow the protocol again."),
 "long_listen": ("samira_shah", "Easy. We are not in a rush. Retry."),
}

FLAG_LINES = {
 "careful_start": ("mira_vale", "In 2026 you chose to check twice. That habit is still on this team."),
 "fast_start": ("mira_vale", "You moved fast in 2026. This year we also move smart."),
 "assisted_once": ("samira_shah", "We helped each other more than once. That is how trust grows."),
 "contamination_noted": ("amara_okonkwo", "That early contaminated sample taught us to sterilize twice."),
 "launch_delay": ("leo_marchetti", "The launch delay kept everyone calm and rested."),
 "signal_leaked": ("yuki_tanaka", "Reporters still ask about the 2026 signal. I say it is unconfirmed."),
 "jumped_to_aliens": ("mira_vale", "We once guessed too far. Now we prefer evidence."),
 "signal_logged_full": ("yuki_tanaka", "Every pulse of the 2026 signal is still in the log."),
 "signal_logged_partial": ("yuki_tanaka", "We only caught part of the 2026 signal. We still listen."),
 "ai_rejected": ("dev_malhotra", "You caught the helper's mistake in 2027. We still check."),
 "premature_hail": ("mira_vale", "We once replied too soon. We will not do that again."),
 "alert_expired": ("mira_vale", "An old alert once waited too long. We learned to triage fast."),
 "mission_retried": ("samira_shah", "You took a second go at a mission. Good teams do that."),
}


def L(speaker, text):
    return {"speaker": speaker, "text": text}


def build_dialogues():
    d = {}
    # genesis opener with a choice that branches and rejoins
    d["genesis_intro"] = {"lines": [
        L("mira_vale", "Welcome to the Assembly Hangar, {callsign}. Today we build the first crew ship for Mars. This year you are our {profession_name}."),
        L("mira_vale", "Everyone here checks their own work, then checks a neighbor's. That is how a small team stays safe."),
        {"choices": [
            {"text": "I like to check every step twice.", "flag": "careful_start", "value": True, "lasting": True, "goto": "genesis_intro_care"},
            {"text": "I am ready to move fast.", "flag": "fast_start", "value": True, "lasting": True, "goto": "genesis_intro_go"}]}]}
    d["genesis_intro_care"] = {"lines": [L("mira_vale", "Good. Slow is smooth, and smooth is fast.")], "next": "genesis_intro_lights"}
    d["genesis_intro_go"] = {"lines": [L("mira_vale", "I love the energy. Just keep your checklist in the other hand.")], "next": "genesis_intro_lights"}
    d["genesis_intro_lights"] = {"lines": [L("mira_vale", "The station lights are green. Find your Duty Station, then talk with two teammates before we close the shift.")]}
    d["genesis_end"] = {"lines": [
        L("mira_vale", "The test stack is up and checked. Well done, {profession_name}."),
        L("samira_shah", "That capsule looks ready for a trip. Thank you for building it right.")]}

    d["countdown_intro"] = {"lines": [
        L("mira_vale", "Launch day, {callsign}. The pad gallery is quiet, and the world is watching a clock."),
        L("samira_shah", "I have flown the simulator a hundred times. It never smelled this much like coffee and metal."),
        L("mira_vale", "Every station calls GO or HOLD today. A HOLD is never a failure. It is a team doing its job.")]}
    d["countdown_end"] = {"lines": [
        L("mira_vale", "Pathfinder is away. Great shift, {profession_name}."),
        L("samira_shah", "I felt the shake in my chest. It was worth every checklist.")]}

    d["transit_intro"] = {"lines": [
        L("mira_vale", "Day 90 of the trip, {callsign}. The corridor is the quietest place on the ship, so every noise matters."),
        L("alex_rivera", "Little hums tell big stories. Keep your ears open."),
        L("mira_vale", "Radio now takes minutes to cross the gap to Earth. Plan before you speak.")]}
    d["transit_end"] = {"lines": [
        L("mira_vale", "Pathfinder stays on course. Good work."),
        L("yuki_tanaka", "Earth got our update. Their answer will take a while.")]}

    d["red_horizon_intro"] = {"lines": [
        L("mira_vale", "Mars below us, {callsign}. Landing day."),
        L("samira_shah", "The sky is butterscotch. I did not expect that."),
        L("mira_vale", "We deploy equipment first, then we rest. In that order.")]}
    d["red_horizon_end"] = {"lines": [
        L("mira_vale", "Boots, wheels, and dishes are down. Good shift, {profession_name}."),
        L("amara_okonkwo", "The first soil test shows rocks and dust. Nothing alive, and plenty to learn.")]}

    d["new_beginnings_intro"] = {"lines": [
        L("mira_vale", "The outpost lights are on, {callsign}. Today is a new beginning."),
        L("yuki_tanaka", "I caught a strange pattern on the dish last night. Probably a glitch, but I logged it."),
        L("mira_vale", "We follow the data and nothing more. Log it, check it, and decide with care.")]}
    d["new_beginnings_end"] = {"lines": [
        L("mira_vale", "Signal status: UNKNOWN SIGNAL, ORIGIN UNCONFIRMED. We keep listening, and we do not guess."),
        L("samira_shah", "Mars has plenty of room for surprises. We stay curious, and we stay careful.")]}

    d["shackleton_relay_intro"] = {"lines": [
        L("mira_vale", "2027, {callsign}. We are building a relay station on the rim of Shackleton crater on the Moon."),
        L("dev_malhotra", "The new AI helper drafts plans fast. It is not always right."),
        L("mira_vale", "Use it like a colleague, not a boss. Check every answer before you act.")]}
    d["shackleton_relay_end"] = {"lines": [
        L("mira_vale", "Verification is a skill, and today it showed. Good work, {profession_name}."),
        L("dev_malhotra", "A good sum beats a fast sum.")]}

    d["ember_drive_intro"] = {"lines": [
        L("mira_vale", "2028, {callsign}. The Ember Drive is a slow engine with a long reach."),
        L("ingrid_solheim", "It pushes about as hard as a sheet of paper on your hand. For months, that adds up."),
        L("mira_vale", "Mind the heat limits. They are safety limits.")]}
    d["ember_drive_end"] = {"lines": [
        L("mira_vale", "The drive ran clean. Good work, {profession_name}."),
        L("alex_rivera", "Slow, steady, and cool. My favorite kind of engine.")]}

    d["living_sensors_intro"] = {"lines": [
        L("mira_vale", "2029, {callsign}. The dome garden is wired with sensors, and some are alive."),
        L("amara_okonkwo", "A glow means the sensor is working. I love that."),
        L("mira_vale", "A reading is only as good as its calibration. Check odd numbers twice.")]}
    d["living_sensors_end"] = {"lines": [
        L("mira_vale", "The dome is watching itself, and we are watching the dome. Good work, {profession_name}."),
        L("leo_marchetti", "Watches and hands agreed. That is how I like it.")]}

    d["first_light_intro"] = {"lines": [
        L("mira_vale", "2030, {callsign}. The array has heard a structured signal. Protocol comes first."),
        L("yuki_tanaka", "It repeats in a pattern that changes on purpose. I cannot explain it with a natural source."),
        L("mira_vale", "We verify, we agree as a team, and only then do we answer. No one replies alone.")]}
    d["first_light_end"] = {"lines": [
        L("mira_vale", "The protocol held. Good work, {profession_name}."),
        L("dev_malhotra", "A prime greeting is on its way. The answer, if any, is years off.")]}

    d["long_listen_intro"] = {"lines": [
        L("mira_vale", "2031, {callsign}. The greeting is on its way. Light is slow, and we are patient."),
        L("samira_shah", "It feels strange to be done and not done at the same time.")]}
    d["long_listen_end"] = {"lines": [
        L("mira_vale", "We keep the array, we keep the garden, and we keep listening. Thank you, {profession_name}."),
        L("samira_shah", "Whatever comes back, we were careful and kind. That is the part we control.")]}

    for mid, per in TALKS.items():
        for crew_id, text in per.items():
            d["%s_talk_%s" % (mid, crew_id)] = {"lines": [L(crew_id, text)]}
    return d
