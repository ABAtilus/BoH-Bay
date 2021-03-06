//Cooking containers are used in ovens and fryers, to hold multiple ingredients for a recipe.
//They work fairly similar to the microwave - acting as a container for objects and reagents,
//which can be checked against recipe requirements in order to cook recipes that require several things

/obj/item/weapon/reagent_containers/cooking_container
	icon = 'icons/obj/aurora/cooking_machines.dmi'
	var/shortname
	var/max_space = 20//Maximum sum of w-classes of foods in this container at once
	var/max_reagents = 80//Maximum units of reagents
	atom_flags = ATOM_FLAG_OPEN_CONTAINER | ATOM_FLAG_NO_REACT
	var/list/insertable = list(
		/obj/item/weapon/reagent_containers/food/snacks,
		/obj/item/weapon/holder,
		/obj/item/weapon/paper,
		/obj/item/weapon/flame/candle
		)

/obj/item/weapon/reagent_containers/cooking_container/Initialize()
	. = ..()
	create_reagents(max_reagents)
	atom_flags |= ATOM_FLAG_OPEN_CONTAINER

/obj/item/weapon/reagent_containers/cooking_container/afterattack(var/obj/target, var/mob/user, var/proximity)
	if(!is_open_container() || !proximity) //Is the container open & are they next to whatever they're clicking?
		return 1 //If not, do nothing.
	if(standard_dispenser_refill(user, target)) //Are they clicking a water tank/some dispenser?
		return 1
	if(standard_pour_into(user, target)) //Pouring into another beaker?
		return
	if(user.a_intent == I_HURT)
		if(standard_splash_mob(user,target))
			return 1
		if(reagents && reagents.total_volume)
			to_chat(user, "<span class='notice'>You splash the contents of \the [src] onto [target].</span>") //They are on harm intent, aka wanting to spill it.
			reagents.splash(target, reagents.total_volume)
			return 1
	. = ..()

/obj/item/weapon/reagent_containers/cooking_container/examine(var/mob/user)
	. = ..()
	if (contents.len)
		var/string = "It contains....</br>"
		for (var/atom/movable/A in contents)
			string += "[A.name] </br>"
		to_chat(user, span("notice", string))
	if (reagents.total_volume)
		to_chat(user, span("notice", "It contains [reagents.total_volume]u of reagents."))


/obj/item/weapon/reagent_containers/cooking_container/attackby(var/obj/item/I as obj, var/mob/user as mob)
	for (var/possible_type in insertable)
		if (istype(I, possible_type))
			if (!can_fit(I))
				to_chat(user, span("warning","There's no more space in the [src] for that!"))
				return 0

			if(!user.unEquip(I))
				return
			I.forceMove(src)
			to_chat(user, span("notice", "You put the [I] into the [src]"))
			return

/obj/item/weapon/reagent_containers/cooking_container/verb/empty()
	set src in oview(1)
	set name = "Empty Container"
	set category = "Object"
	set desc = "Removes items from the container, excluding reagents."

	do_empty(usr)

/obj/item/weapon/reagent_containers/cooking_container/proc/do_empty(mob/user)
	if (!isliving(user))
		//Here we only check for ghosts. Animals are intentionally allowed to remove things from oven trays so they can eat it
		return

	if (user.stat || user.restrained())
		to_chat(user, "<span class='notice'>You are in no fit state to do this.</span>")
		return

	if (!Adjacent(user))
		to_chat(user, "You can't reach [src] from here.")
		return

	if (!contents.len)
		to_chat(user, span("warning", "There's nothing in the [src] you can remove!"))
		return

	for (var/atom/movable/A in contents)
		A.forceMove(get_turf(src))

	to_chat(user, span("notice", "You remove all the solid items from the [src]."))

/obj/item/weapon/reagent_containers/cooking_container/proc/check_contents()
	if (contents.len == 0)
		if (!reagents || reagents.total_volume == 0)
			return 0//Completely empty
	else if (contents.len == 1)
		if (!reagents || reagents.total_volume == 0)
			return 1//Contains only a single object which can be extracted alone
	return 2//Contains multiple objects and/or reagents

/obj/item/weapon/reagent_containers/cooking_container/AltClick(var/mob/user)
	do_empty(user)

//Deletes contents of container.
//Used when food is burned, before replacing it with a burned mess
/obj/item/weapon/reagent_containers/cooking_container/proc/clear()
	for (var/atom/a in contents)
		qdel(a)

	if (reagents)
		reagents.clear_reagents()

/obj/item/weapon/reagent_containers/cooking_container/proc/label(var/number, var/CT = null)
	//This returns something like "Fryer basket 1 - empty"
	//The latter part is a brief reminder of contents
	//This is used in the removal menu
	. = shortname
	if (!isnull(number))
		.+= " [number]"
	.+= " - "
	if (CT)
		.+=CT
	else if (contents.len)
		for (var/obj/O in contents)
			.+=O.name//Just append the name of the first object
			return
	else if (reagents && reagents.total_volume > 0)
		var/datum/reagent/R = reagents.get_master_reagent()
		.+=R.name//Append name of most voluminous reagent
		return
	else
		. += "empty"


/obj/item/weapon/reagent_containers/cooking_container/proc/can_fit(var/obj/item/I)
	var/total = 0
	for (var/obj/item/J in contents)
		total += J.w_class

	if((max_space - total) >= I.w_class)
		return 1


//Takes a reagent holder as input and distributes its contents among the items in the container
//Distribution is weighted based on the volume already present in each item
/obj/item/weapon/reagent_containers/cooking_container/proc/soak_reagent(var/datum/reagents/holder)
	var/total = 0
	var/list/weights = list()
	for (var/obj/item/I in contents)
		if (I.reagents && I.reagents.total_volume)
			total += I.reagents.total_volume
			weights[I] = I.reagents.total_volume

	if (total > 0)
		for (var/obj/item/I in contents)
			if (weights[I])
				holder.trans_to(I, weights[I] / total)


/obj/item/weapon/reagent_containers/cooking_container/oven
	name = "oven dish"
	shortname = "shelf"
	desc = "Put ingredients in this; designed for use with an oven. Warranty void if used."
	icon_state = "ovendish"
	max_space = 30
	max_reagents = 120

/obj/item/weapon/reagent_containers/cooking_container/pan
	name = "pan"
	shortname = "pan"
	desc = "Chuck ingredients in this to fry something on the stove."
	icon_state = "pan"
	max_space = 30
	max_reagents = 30
	slot_flags = SLOT_HEAD
	force = 15
	hitsound = 'sound/weapons/smash.ogg'
	atom_flags = ATOM_FLAG_OPEN_CONTAINER // so we can melt things in it
	temperature_coefficient = 8 // much faster

/obj/item/weapon/reagent_containers/cooking_container/pan/New(var/newloc, var/mat_key) // we use New instead of Initialize because, uh, material, i guess
	..(newloc)
	var/material/material = SSmaterials.get_material_by_name(mat_key ? mat_key : MATERIAL_STEEL)
	if(material.name != MATERIAL_STEEL)
		color = material.icon_colour
	name = "[material.display_name] [initial(name)]"

/obj/item/weapon/reagent_containers/cooking_container/fryer
	name = "fryer basket"
	shortname = "basket"
	desc = "Put ingredients in this; designed for use with a deep fryer. Warranty void if used."
	icon_state = "basket"