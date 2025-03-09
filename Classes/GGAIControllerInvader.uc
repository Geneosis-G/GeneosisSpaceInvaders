class GGAIControllerInvader extends GGAIController;

var float mDestinationOffset;
var kActorSpawnable destActor;
var float totalTime;
var bool isArrived;

var float targetRadius;
var float mDetectionRadius;

var ParticleSystem mBrainwashTemplate;
var ParticleSystemComponent mBrainwashPSC;

var SpaceInvaders myMut;

/**
 * Cache the NPC and mOriginalPosition
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local ProtectInfo destination;

	super.Possess(inPawn, bVehicleTransition);

	if(mMyPawn == none)
		return;

	FindSpaceInvaders();

	mMyPawn.mProtectItems.Length=0;
	SpawnDestActor();
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " destActor=" $ destActor);
	destActor.SetLocation(mMyPawn.Location);

	destination.ProtectItem = mMyPawn;
	destination.ProtectRadius = 1000000.f;
	mMyPawn.mProtectItems.AddItem(destination);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mMyPawn.mProtectItems[0].ProtectItem=" $ mMyPawn.mProtectItems[0].ProtectItem);
	StandUp();
	FindBestState();
}

event UnPossess()
{
	if(destActor != none)
	{
		destActor.ShutDown();
		destActor.Destroy();
		destActor = none;
	}
	super.UnPossess();
	mMyPawn=none;
}

function FindSpaceInvaders()
{
	if(myMut != none)
		return;

	foreach AllActors(class'SpaceInvaders', myMut)
	{
		break;
	}
}

function SpawnDestActor()
{
	if(destActor == none || destActor.bPendingDelete)
	{
		destActor = Spawn(class'kActorSpawnable', mMyPawn,,,,,true);
		destActor.SetHidden(true);
		destActor.SetPhysics(PHYS_None);
		destActor.CollisionComponent=none;
	}
}

event Tick( float deltaTime )
{
	if(mMyPawn == none)//Handle being taken out of the pawn
	{
		return;
	}

	// Optimisation
	if( mMyPawn.IsInState( 'UnrenderedState' ) )
	{
		return;
	}

	Super.Tick( deltaTime );
	//Fix dest actor is none
	SpawnDestActor();
	// Fix dead attacked pawns
	if( mPawnToAttack != none )
	{
		if( mPawnToAttack.bPendingDelete )
		{
			mPawnToAttack = none;
		}
	}
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " state=" $ mCurrentState);
	if(!mMyPawn.mIsRagdoll)
	{
		//Fix NPC with no collisions
		if(mMyPawn.CollisionComponent == none)
		{
			mMyPawn.CollisionComponent = mMyPawn.Mesh;
		}

		//Fix NPC rotation
		UnlockDesiredRotation();
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " attack " $ mPawnToAttack);
		if(mPawnToAttack != none)
		{
			Pawn.SetDesiredRotation( rotator( Normal2D( mPawnToAttack.Location - Pawn.Location ) ) );
			mMyPawn.LockDesiredRotation( true );
		}
		else
		{
			if(IsZero(mMyPawn.Velocity))
			{
				if(isArrived)
				{
					StartRandomMovement();
				}
				else if(!IsTimerActive( NameOf( StartRandomMovement ) ))
				{
					SetTimer(RandRange(1.0f, 10.0f), false, nameof( StartRandomMovement ) );
				}
			}
			else
			{
				if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mRunAnimationInfo ) )
				{
					mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );
				}
			}
		}
		FindBestState();
		// if waited too long to before reaching some place or some item, abandon
		totalTime = totalTime + deltaTime;
		if(totalTime > 11.f)
		{
			totalTime=0.f;
			mMyPawn.SetRagdoll(true);
			EndAttack();
		}
	}
	else
	{
		//Fix NPC not standing up
		if(!IsTimerActive( NameOf( StandUp ) ))
		{
			StartStandUpTimer();
		}

		//Make swapper swim
		if(mMyPawn.mInWater)
		{
			//TODO
		}
	}
}

function FindBestState()
{
	if(mPawnToAttack != none)
	{
		if(!IsValidEnemy(mPawnToAttack) || !PawnInRange(mPawnToAttack))
		{
			EndAttack();
		}
		else if(mCurrentState == '')
		{
			GotoState( 'ChasePawn' );
		}
	}
	else if(mCurrentState != 'RandomMovement')
	{
		GotoState( 'RandomMovement' );
	}
}

function StartRandomMovement()
{
	local vector dest;
	local int OffsetX;
	local int OffsetY;

	if(mPawnToAttack != none || mMyPawn.mIsRagdoll)
	{
		return;
	}
	totalTime=-10.f;
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " start random movement");

	OffsetX = Rand(1000)-500;
	OffsetY = Rand(1000)-500;

	dest.X = mMyPawn.Location.X + OffsetX;
	dest.Y = mMyPawn.Location.Y + OffsetY;
	dest.Z = mMyPawn.Location.Z;

	destActor.SetLocation(dest);
	isArrived=false;
	//mMyPawn.SetDesiredRotation(rotator(Normal(dest -  mMyPawn.Location)));

}

//All work done in EnemyNearProtectItem()
function CheckVisibilityOfGoats();
function CheckVisibilityOfEnemies();
event SeePlayer( Pawn Seen );
event SeeMonster( Pawn Seen );

/**
 * Helper function to determine if the last seen goat is near a given protect item
 * @param  protectInformation - The protectInfo to check against
 * @return true / false depending on if the goat is near or not
 */
function bool EnemyNearProtectItem( ProtectInfo protectInformation, out GGPawn enemyNear )
{
	local GGPawn tmpPawn;
	local array<GGPawn> visiblePawns;
	local int size;

	foreach VisibleCollidingActors(class'GGPawn', tmpPawn, mDetectionRadius, mMyPawn.Location)
	{
		if(IsValidEnemy(tmpPawn))
		{
			visiblePawns.AddItem(tmpPawn);
		}
	}

	size=visiblePawns.Length;
	if(size > 0)
	{
		enemyNear=visiblePawns[Rand(size)];
	}
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " EnemyNearProtectItem=" $ enemyNear);
	return (enemyNear != none);
}

function StartProtectingItem( ProtectInfo protectInformation, GGPawn threat )
{
	local float h;

	StopAllScheduledMovement();
	totalTime=0.f;

	mCurrentlyProtecting = protectInformation;

	mPawnToAttack = threat;
	mPawnToAttack.GetBoundingCylinder(targetRadius, h);

	StartLookAt( threat, 5.0f );

	GotoState( 'ChasePawn' );
}

function AttackPawn()
{
	local GGPawn gpawn;

	// AOE attack
	foreach OverlappingActors( class'GGPawn', gpawn, mMyPawn.mAttackRange, mMyPawn.Location)
    {
		if(IsValidEnemy(gpawn))
	    {
	        myMut.Brainwash(gpawn);
	    }
    }
    // Makes sure the original target is brainwashed
    myMut.Brainwash(GGPawn(mPawnToAttack));

	EndAttack();
	FindBestState();
}

function StartAttack( Pawn pawnToAttack )
{
	mBrainwashPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(mBrainwashTemplate, mMyPawn.mesh, 'Head');
	mBrainwashPSC.bAutoActivate = true;
	mMyPawn.SetAnimationInfoStruct( mMyPawn.mIdleAnimationInfo );

	if(!IsTimerActive(NameOf(AttackPawn)))
	{
		SetTimer(0.5f, false, NameOf(AttackPawn));
	}
}

event PawnFalling();//do NOT go into wait for landing state

state RandomMovement extends MasterState
{
	/**
	 * Called by APawn::moveToward when the point is unreachable
	 * due to obstruction or height differences.
	 */
	event MoveUnreachable( vector AttemptedDest, Actor AttemptedTarget )
	{
		if( AttemptedDest == mOriginalPosition && mMyPawn != none)
		{
			if( mMyPawn.IsDefaultAnimationRestingOnSomething() )
			{
			    mMyPawn.mDefaultAnimationInfo =	mMyPawn.mIdleAnimationInfo;
			}

			mOriginalPosition = mMyPawn.Location;
			mMyPawn.ZeroMovementVariables();

			StartRandomMovement();
		}
	}
Begin:
	mMyPawn.ZeroMovementVariables();
	while( mMyPawn != none && mPawnToAttack == none)
	{
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " STATE OK!!!");
		if(VSize2D(destActor.Location - mMyPawn.Location) > mDestinationOffset)
		{
			MoveToward (destActor);
		}
		else
		{
			if(!isArrived)
			{
				isArrived=true;
			}
			totalTime=0.f;
			MoveToward (mMyPawn,, mDestinationOffset);// Ugly hack to prevent "runnaway loop" error
		}
	}
	mMyPawn.ZeroMovementVariables();
}

state ChasePawn extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );

	while( mMyPawn != none && VSize( mMyPawn.Location - mPawnToAttack.Location ) - targetRadius > mMyPawn.mAttackRange || !ReadyToAttack() )
	{
		if( mPawnToAttack == none )
		{
			ReturnToOriginalPosition();
			break;
		}

		MoveToward( mPawnToAttack,, mDestinationOffset );
	}

	FinishRotation();
	GotoState( 'Attack' );
}

state Attack extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	Focus = mPawnToAttack;

	StartAttack( mPawnToAttack );
	FinishRotation();
}

/**
 * Helper function to determine if our pawn is close to a protect item, called when we arrive at a pathnode
 * @param currentlyAtNode - The pathNode our pawn just arrived at
 * @param out_ProctectInformation - The info about the protect item we are near if any
 * @return true / false depending on if the pawn is near or not
 */
function bool NearProtectItem( PathNode currentlyAtNode, out ProtectInfo out_ProctectInformation )
{
	out_ProctectInformation=mMyPawn.mProtectItems[0];
	return true;
}

function bool IsValidEnemy( Pawn newEnemy )
{
	local GGPawn gpawn;
	gpawn = GGPawn(newEnemy);
	return (
		gpawn != none
		&& GGNpcInvader(gpawn) == none
		&& !myMut.IsBrainwashed(gpawn))
		&& newEnemy.DrivenVehicle == none;
}

function ResumeDefaultAction()
{
	super.ResumeDefaultAction();
	FindBestState();
}

function ReturnToOriginalPosition()
{
	FindBestState();
}

function DelayedGoToProtect()
{
	UnlockDesiredRotation();
	FindBestState();
}

/**
 * Try to figure out what we want to do after we have stand up
 */
function DeterminWhatToDoAfterStandup()
{
	FindBestState();
}

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	local GGPawn gpawn;

	gpawn = GGPawn( ragdolledActor );

	if( ragdolledActor == mMyPawn && isRagdoll )
	{
		if( IsTimerActive( NameOf( StopPointing ) ) )
		{
			StopPointing();
		}

		if( IsTimerActive( NameOf( StopLookAt ) ) )
		{
			StopLookAt();
		}

		if( mCurrentState == 'ProtectItem' )
		{
			ClearTimer( nameof( AttackPawn ) );
			ClearTimer( nameof( DelayedGoToProtect ) );
		}
		StopAllScheduledMovement();
		StartStandUpTimer();
		UnlockDesiredRotation();
	}

	if( gpawn != none)
	{
		if( gpawn == mLookAtActor )
		{
			StopLookAt();
		}
	}
}

function bool GoatCarryingDangerItem();
function bool PawnUsesScriptedRoute();
function StartInteractingWith( InteractionInfo intertactionInfo );
function OnTrickMade( GGTrickBase trickMade );
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum );
function OnKismetActivated( SequenceAction activatedKismet );
function bool CanPawnInteract();
function OnManual( Actor manualPerformer, bool isDoingManual, bool wasSuccessful );
function OnWallRun( Actor runner, bool isWallRunning );
function OnWallJump( Actor jumper );
function ApplaudGoat();
function PointAtGoat();
function StopPointing();
function bool WantToPanicOverTrick( GGTrickBase trickMade );
function bool WantToApplaudTrick( GGTrickBase trickMade  );
function bool WantToPanicOverKismetTrick( GGSeqAct_GiveScore trickRelatedKismet );
function bool WantToApplaudKismetTrick( GGSeqAct_GiveScore trickRelatedKismet );
function bool NearInteractItem( PathNode currentlyAtNode, out InteractionInfo out_InteractionInfo );
function bool ShouldApplaud();
function bool ShouldNotice();
event GoatPickedUpDangerItem( GGGoat goat );
function Panic();
function Dance(optional bool forever);
function PawnDied(Pawn inPawn);

DefaultProperties
{
	mDetectionRadius=5000.f
	mDestinationOffset=180.f
	bIsPlayer=true

	mAttackIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mCheckProtItemsThreatIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mVisibilityCheckIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)

	mBrainwashTemplate=ParticleSystem'Zombie_Particles.Particles.Mind_Control_Burst2'
}
