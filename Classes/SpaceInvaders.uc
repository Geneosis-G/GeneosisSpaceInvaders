class SpaceInvaders extends GGMutator;

var array<GGGoat> mGoats;
var float timeElapsed;
var float managementTimer;
var float SRTimeElapsed;
var float spawnRemoveTimer;
var float spawnRadius;
var int minInvadersCount;
var int maxInvadersCount;

var array<GGPawn> mHumanPawns;
var bool mInvasionStarted;

var array<GGNpc> mRemovableNPCs;
var int mInvadersNPCCount;
var array<int> mInvadersNPCsToSpawnForPlayer;

var array<GGPawn> mBrainwashedPawns;

var int mFlyingSaucersCount;
var array<InvaderFlyingSaucer> mFlyingSaucers;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			mGoats.AddItem(goat);
		}
	}

	super.ModifyPlayer( other );
}

function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	local GGPawn damagedPawn, playerPawn;
	local GGNpcInvader newInvader;
	local vector spawnLoc;
	local rotator spawnRot;

	if(mInvasionStarted)
		return;

	damagedPawn = GGPawn(damagedActor);
	playerPawn = GGPawn(damageCauser);
	if(damagedPawn != none && PlayerController(damagedPawn.Controller) == none && IsHuman(damagedPawn)
	&& playerPawn != none && PlayerController(playerPawn.Controller) != none && mHumanPawns.Find(damagedPawn) == INDEX_NONE)
	{
		// 1 chance out of 3 to start the invasion
		if(Rand(3) == 0)
		{
			// Replace the NPC by the first invader
			spawnLoc = damagedPawn.Location;
			spawnRot = damagedPawn.Rotation;
			DestroyNPC(damagedPawn);
			newInvader = Spawn( class'GGNpcInvader',,, spawnLoc, spawnRot,, true);
			if(newInvader != none)
			{
				newInvader.InitInvader();
				newInvader.TakeDamage( damage, playerPawn.COntroller, newInvader.Location, momentum, dmgType,, damageCauser);
			}

			StartInvasion();
		}
		else
		{
			// Only test if each human is an invader once
			mHumanPawns.AddItem(damagedPawn);
		}
	}
}

function StartInvasion()
{
	local int actorCount;
	local Actor actorItr;

	//reset useless array
	mHumanPawns.Length = 0;

	// Compute number of flying saucers needed depending on the number of items in the whole map
	actorCount=0;
	foreach AllActors( class'Actor', actorItr, class'GGGrabbableActorInterface' )
	{
		actorCount++;
	}
	//WorldInfo.Game.Broadcast(self, "actorCount=" $ actorCount);
	mFlyingSaucersCount = (actorCount / 1000) + 1;

	// Start the invasion
	mInvasionStarted=true;
}

function bool IsHuman(GGPawn gpawn)
{
	local GGAIControllerMMO AIMMO;

	if(InStr(string(gpawn.Mesh.PhysicsAsset), "CasualGirl_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "CasualMan_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "SportyMan_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "HeistNPC_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "Explorer_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "SpaceNPC_Physics") != INDEX_NONE)
	{
		return true;
	}
	AIMMO=GGAIControllerMMO(gpawn.Controller);
	if(AIMMO == none)
	{
		return false;
	}
	else
	{
		return AIMMO.PawnIsHuman();
	}
}

simulated event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	if(!mInvasionStarted)
		return;

	timeElapsed=timeElapsed+deltaTime;
	if(timeElapsed > managementTimer)
	{
		timeElapsed=0.f;
		GenerateInvadersNPCLists();
	}
	SRTimeElapsed=SRTimeElapsed+deltaTime;
	if(SRTimeElapsed > spawnRemoveTimer)
	{
		SRTimeElapsed=0.f;
		SpawnInvadersNPCFromList();
		RemoveInvadersNPCFromList();
		SpawnFlyingSaucers();
	}
}

function GenerateInvadersNPCLists()
{
	local GGNpcInvader invadersNPC;
	local array<int> invadersNPCsForPlayer;
	local bool isRemovable;
	local int nbPlayers, i;
	local vector dist;

	mRemovableNPCs.Length=0;

	nbPlayers=mGoats.Length;
	mInvadersNPCsToSpawnForPlayer.Length = 0;
	mInvadersNPCsToSpawnForPlayer.Length = nbPlayers;
	invadersNPCsForPlayer.Length = nbPlayers;
	mInvadersNPCCount=0;
	//Find all invaders NPCs close to each player
	foreach AllActors(class'GGNpcInvader', invadersNPC)
	{
		//WorldInfo.Game.Broadcast(self, MMONPCAI $ " possess " $ invadersNPC);
		mInvadersNPCCount++;
		isRemovable=true;

		for(i=0 ; i<nbPlayers ; i++)
		{
			dist=mGoats[i].Location - invadersNPC.Location;
			if(VSize2D(dist) < spawnRadius)
			{
				invadersNPCsForPlayer[i]++;
				isRemovable=false;
			}
		}

		if(isRemovable)
		{
			mRemovableNPCs.AddItem(invadersNPC);
		}
	}

	for(i=0 ; i<nbPlayers ; i++)
	{
		mInvadersNPCsToSpawnForPlayer[i]=minInvadersCount-invadersNPCsForPlayer[i];
	}
	//WorldInfo.Game.Broadcast(self, "MMONPCs to spawn " $ mInvadersNPCsToSpawnForPlayer[0]);
}

function SpawnInvadersNPCFromList()
{
	local GGNpcInvader newNpc;
	local int nbPlayers, i;

	//Spawn new goat and sheeps NPCs if needed
	nbPlayers=mGoats.Length;
	for(i=0 ; i<nbPlayers ; i++)
	{
		if(mInvadersNPCsToSpawnForPlayer.Length > 0 && mInvadersNPCsToSpawnForPlayer[i] > 0)
		{
			mInvadersNPCsToSpawnForPlayer[i]--;
			newNpc = Spawn( class'GGNpcInvader',,, GetRandomSpawnLocation(mGoats[i].Location), GetRandomRotation());
			if(newNpc != none)
			{
				newNpc.InitInvader();
				mInvadersNPCCount++;
			}
			break;
		}
	}
}

function RemoveInvadersNPCFromList()
{
	local GGNpc NPCToRemove;
	local int nbPlayers, goatsToRemove;

	//Remove old MMONPCs and infected NPCs if needed
	nbPlayers=mGoats.Length;
	goatsToRemove=mInvadersNPCCount-(maxInvadersCount*nbPlayers);
	if(mRemovableNPCs.Length > 0 && goatsToRemove > 0)
	{
		NPCToRemove=mRemovableNPCs[0];
		mRemovableNPCs.Remove(0, 1);

		DestroyNPC(NPCToRemove);
		mInvadersNPCCount--;
	}
}

function SpawnFlyingSaucers()
{
	local InvaderFlyingSaucer newSaucer;

	if(mFlyingSaucers.Length < mFlyingSaucersCount)
	{
		//WorldInfo.Game.Broadcast(self, "Spawning flying saucer");
		newSaucer = Spawn( class'InvaderFlyingSaucer', self,, GetRandomSpawnLocation(mGoats[0].Location, spawnRadius*8.f, mGoats[0].Location.Z + 2000),,, true);
		if(newSaucer != none)
		{
			mFlyingSaucers.AddItem(newSaucer);
		}
	}
}

function DestroyNPC(GGPawn gpawn)
{
	local int i;

	for( i = 0; i < gpawn.Attached.Length; i++ )
	{
		if(GGGoat(gpawn.Attached[i]) == none)
		{
			gpawn.Attached[i].ShutDown();
			gpawn.Attached[i].Destroy();
		}
	}
	gpawn.ShutDown();
	gpawn.Destroy();
}

function vector GetRandomSpawnLocation(vector center, optional float radius=0, optional float zValue=0)
{
	local vector dest;
	local rotator rot;
	local float dist;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	rot=GetRandomRotation();

	dist=spawnRadius;
	if(radius != 0)
	{
		dist = radius;
	}
	dist=RandRange(dist/2.f, dist);

	dest=center+Normal(Vector(rot))*dist;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	hitLocation.Z+=30;
	if(zValue != 0)
	{
		hitLocation.Z = zValue;
	}

	return hitLocation;
}

function rotator GetRandomRotation()
{
	local rotator rot;

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	return rot;
}

function Brainwash(GGPawn gpawn)
{
	local BrainwashedPawn newBp;

	if(IsBrainwashed(gpawn))
		return;

	newBp = Spawn(class'BrainwashedPawn', self);
	newBp.BrainwashPawn(gpawn);
	mBrainwashedPawns.AddItem(gpawn);
}

function bool IsBrainwashed(GGPawn gpawn)
{
	return mBrainwashedPawns.Find(gpawn) != INDEX_NONE;
}

function OnBrainwashEnded(GGPawn gpawn)
{
	mBrainwashedPawns.RemoveItem(gpawn);
}

// Is any saucer already on top of that location
function bool IsFlyingSaucerInRange(vector targetPos)
{
	local InvaderFlyingSaucer saucer;
	local float r, h;

	foreach mFlyingSaucers(saucer)
	{
		saucer.GetBoundingCylinder(r, h);
		if(VSize2D(targetPos - saucer.Location) <= r * 2.f
		||	VSize2D(targetPos - saucer.mTargetActor.Location) <= r * 2.f)
		{
			return true;
		}
	}

	return false;
}

function OnFlyingSaucerDestroyed(InvaderFlyingSaucer saucer)
{
	mFlyingSaucers.RemoveItem(saucer);
}

DefaultProperties
{
	managementTimer=1.f
	spawnRemoveTimer=0.1f
	spawnRadius=5000.f
	minInvadersCount=5
	maxInvadersCount=10
}