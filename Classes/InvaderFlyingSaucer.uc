//-----------------------------------------------------------
//
//-----------------------------------------------------------
class InvaderFlyingSaucer extends GGFlyingSaucer;

var SpaceInvaders myMut;

var EPhysics mOldPhys;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	myMut=SpaceInvaders(Owner);
}

function StartBeaming()
{
	local int i;
	local GGSVehicle vehicleTarget;

	// Reworked original code //
	Velocity = vect( 0.0f, 0.0f, 0.0f );
	mOldPhys = mTargetActor.Physics;
	mIsBeaming = true;
	mBeamMesh.SetHidden( false );

	vehicleTarget = GGSVehicle( mTargetActor );

	if( vehicleTarget != none )
	{
		if( GGGoat( vehicleTarget.Driver ) != none )
		{
			vehicleTarget.KickOutDriver();
		}

		for( i = 0; i < vehicleTarget.mPassengerSeats.Length; i++ )
		{
			if( GGGoat( vehicleTarget.mPassengerSeats[ i ].PassengerPawn  ) != none )
			{
	             vehicleTarget.mPassengerSeats[ i ].VehiclePassengerSeat.DriverLeave( false );
			}
		}
	}

	if( mAudioComponentBeam == none )
	{
		mAudioComponentBeam = CreateAudioComponent( mBeamStartSoundCue );
	}
	else
	{
		mAudioComponentBeam.Stop();
		mAudioComponentBeam.SoundCue = mBeamStartSoundCue;
	}
	mAudioComponentBeam.Play();
}

function ChaseActor( float delta )
{
	if(!IsActorValid(mTargetActor, true))
	{
		FindAndAssignNewTargetActor();
		return;
	}
	// This way validity check passes if actor is under saucer
	mOverrideValidCheckForActor = mTargetActor;
	super.ChaseActor(delta);
	mOverrideValidCheckForActor = none;
}

function BeamUpActor( float delta )
{
	local vector upwardsVel, newLocation;
	local GGGoat goatItr;
	local bool getNewTarget;
	local int i;

	foreach WorldInfo.AllPawns( class'GGGoat', goatItr )
	{
		if( goatItr.mGrabbedItem == mTargetActor )
		{
			goatItr.DropGrabbedItem();
		}
	}

	upwardsVel = vect( 0.0f, 0.0f, 500.0f );

    mTargetActor.SetPhysics( PHYS_None );

	newLocation = Location;
	newLocation.Z = mTargetActor.Location.Z;

	newLocation += upwardsVel * delta;

	mTargetActor.SetLocation( newLocation );

	mBeamDuration -= delta;

	if(!IsActorValid(mTargetActor, true))
	{
		getNewTarget = true;

		mTargetActor.SetPhysics( mOldPhys );
	}
	else if( mTargetActor.Location.Z >= Location.Z )
	{
		getNewTarget = true;

		for( i = 0; i < mTargetActor.Attached.Length; i++ )
		{
			mTargetActor.Attached[ i ].ShutDown();
			mTargetActor.Attached[ i ].Destroy();
		}

		mTargetActor.ShutDown();
		mTargetActor.Destroy();
	}
	else if( mBeamDuration <= 0.0f )
	{
		getNewTarget = true;

		mIgnoredActors.AddItem( mTargetActor );

		mTargetActor.SetPhysics( mOldPhys );
	}

	if( getNewTarget )
	{
		EndBeaming();
	}
}

function bool IsTargetValid( Actor target )
{
	return IsActorValid(target) || mOverrideValidCheckForActor == target;
}

function bool IsActorValid( Actor target, bool ignoreLocation=false)
{
	return target != none
		&& !target.bHidden
		&& (	(GGPawn(target) != none
				&& PlayerController(GGPawn(target).Controller) == none
				&& GGNpcInvader(target) == none)
			|| GGSVehicle(target) != none
			|| GGKActor(target) != none)
		&& mIgnoredActors.Find(target) == INDEX_NONE
		&& (ignoreLocation || !myMut.IsFlyingSaucerInRange(target.Location));
}

simulated event Destroyed()
{
	if(myMut != none)
	{
		myMut.OnFlyingSaucerDestroyed(self);
	}

	super.Destroyed();
}

DefaultProperties
{
	//Random character, needed for tick loop to be processed
	mMeshStringToSearchFor="*"
}