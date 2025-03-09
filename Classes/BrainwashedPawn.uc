class BrainwashedPawn extends Actor;

var SpaceInvaders myMut;
var GGPawn mPawn;
var GGGoat mGoat;
var GGNpc mNpc;
var bool mDestroyed;

var ParticleSystem mBrainwashTemplate;
var ParticleSystemComponent mBrainwashPSC;
var AudioComponent mBrainwashHypnotisedComp;
var SoundCue mBrainwashHypnotisedSound;
var float mBrainwashDuration;
var float mBrainwashEffectDelay;

var int mEnforcedDirection;
var float mPushForce;
var float mRagdollPushForce;

var array<NPCAnimationInfo> mAnimations;
var array<SoundCue> mSounds;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	myMut=SpaceInvaders(Owner);
}

function bool IsValidPawn(GGPawn gpawn)
{
	return !mDestroyed && gpawn != none && !gpawn.bPendingDelete && !gpawn.bHidden && gpawn.DrivenVehicle == none;
}
//Empty implementation
function BrainwashPawn(GGPawn gpawn)
{
	if(mPawn != none || !IsValidPawn(gpawn))
		return;

	mPawn = gpawn;
	mGoat = GGGoat(gpawn);
	mNpc = GGNpc(gpawn);

	SetLocation(mPawn.Location);
	SetBase(mPawn);

	if(mBrainwashPSC == None)
	{
		mBrainwashPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( mBrainwashTemplate, mPawn.mesh, 'Head', true );
	}

	if( mBrainwashHypnotisedComp == none && PlayerController(mPawn.Controller) != none)
	{
		mBrainwashHypnotisedComp = mPawn.CreateAudioComponent( mBrainwashHypnotisedSound, false );

		// If too many sounds are playing or if there is no one around to hear the sound, then the audio component will not be created.
		if( mBrainwashHypnotisedComp != none )
		{
			mBrainwashHypnotisedComp.FadeIn( 0.2f, 1 );
		}
	}

	SetupAnimations();
	SetupSounds();

	//Start end of effect timer
	SetTimer(PlayerController(mPawn.Controller) != none ? mBrainwashDuration/2.f : mBrainwashDuration, false, NameOf(SelfDestroy));

	//Start brainwash timer
	SetTimer(mBrainwashEffectDelay, true, NameOf(BeBrainwashed));
	BeBrainwashed();
}

function SetupAnimations()
{
	local int i;

	if(mNpc == none)
		return;

	mAnimations.AddItem(mNpc.mDanceAnimationInfo);
	mAnimations.AddItem(mNpc.mPanicAtWallAnimationInfo);
	mAnimations.AddItem(mNpc.mPanicAnimationInfo);
	mAnimations.AddItem(mNpc.mAttackAnimationInfo);
	mAnimations.AddItem(mNpc.mAngryAnimationInfo);
	mAnimations.AddItem(mNpc.mIdleAnimationInfo);
	mAnimations.AddItem(mNpc.mApplaudAnimationInfo);
	mAnimations.AddItem(mNpc.mRunAnimationInfo);
	mAnimations.AddItem(mNpc.mNoticeGoatAnimationInfo);
	mAnimations.AddItem(mNpc.mIdleSittingAnimationInfo);

	if(GGNpcHeist(mNpc) != none)
	{
		mAnimations.AddItem(GGNpcHeist(mNpc).mPickupAnimationInfo);
	}

	if(GGNpcPolice(mNpc) != none)
	{
		mAnimations.AddItem(GGNpcPolice(mNpc).mPickupCriminalAnimation);
	}

	if(GGNPCMMOAbstract(mNpc) != none)
	{
		mAnimations.AddItem(GGNPCMMOAbstract(mNpc).mConversationAnimationInfo);
	}

	if(GGNPCMMOEnemy(mNpc) != none)
	{
		mAnimations.AddItem(GGNPCMMOEnemy(mNpc).mScriptedRouteAnimationInfo);
		mAnimations.AddItem(GGNPCMMOEnemy(mNpc).mIdleTalkingAnimationInfo);
	}

	if(GGNPCMMOWoodpeckerElfAbstract(mNpc) != none)
	{
		mAnimations.AddItem(GGNPCMMOWoodpeckerElfAbstract(mNpc).mWoodpeckerAnimationInfo);
	}

	if(GGNpcSpace(mNpc) != none)
	{
		mAnimations.AddItem(GGNpcSpace(mNpc).mBullyingGoatAnimationInfo);
	}

	if(GGNpcSurvivorAbstract(mNpc) != none)
	{
		mAnimations.AddItem(GGNpcSurvivorAbstract(mNpc).mChasingAnimationInfo);
	}

	if(GGNpcZombieAbstract(mNpc) != none)
	{
		mAnimations.AddItem(GGNpcZombieAbstract(mNpc).mKickAttackAnimationInfo);
	}

	// Remove items with no animation
	for(i = 0 ; i<mAnimations.Length ; i=i)
	{
		if(mAnimations[i].AnimationNames.Length == 0)
		{
			mAnimations.Remove(i, 1);
		}
		else
		{
			i++;
		}
	}
}

function SetupSounds()
{
	local SoundCue tmpSound;

	if(mNpc == none)
		return;

	foreach mNpc.mAllKnockedOverSounds(tmpSound)
	{
		mSounds.AddItem(tmpSound);
	}
	foreach mNpc.mPanicSounds(tmpSound)
	{
		mSounds.AddItem(tmpSound);
	}
	foreach mNpc.mApplaudSounds(tmpSound)
	{
		mSounds.AddItem(tmpSound);
	}
	foreach mNpc.mAngrySounds(tmpSound)
	{
		mSounds.AddItem(tmpSound);
	}
	foreach mNpc.mNoticeGoatSounds(tmpSound)
	{
		mSounds.AddItem(tmpSound);
	}

	if(GGNpcPolice(mNpc) != none)
	{
		foreach GGNpcPolice(mNpc).mPoliceAggroSounds(tmpSound)
		{
			mSounds.AddItem(tmpSound);
		}
	}

	if(GGNPCMMOAbstract(mNpc) != none)
	{
		foreach GGNPCMMOAbstract(mNpc).mAllConversationSoundCues(tmpSound)
		{
			mSounds.AddItem(tmpSound);
		}
	}

	if(GGNpcSpace(mNpc) != none)
	{
		foreach GGNpcSpace(mNpc).mBullyingSounds(tmpSound)
		{
			mSounds.AddItem(tmpSound);
		}
	}

	if(GGNpcSurvivorAbstract(mNpc) != none)
	{
		foreach GGNpcSurvivorAbstract(mNpc).mSurvivorChasingSound(tmpSound)
		{
			mSounds.AddItem(tmpSound);
		}
	}

	if(GGNpcZombieAbstract(mNpc) != none)
	{
		foreach GGNpcZombieAbstract(mNpc).mAllAttackSounds(tmpSound)
		{
			mSounds.AddItem(tmpSound);
		}
		foreach GGNpcZombieAbstract(mNpc).mAllChaseSounds(tmpSound)
		{
			mSounds.AddItem(tmpSound);
		}
	}
}

event Tick( float deltaTime )
{
	local vector dir;
	local float force;
	local EPhysics oldPhys;

	super.Tick( deltaTime );

	if(!IsValidPawn(mPawn))
	{
		SelfDestroy();
		return;
	}

	//Push goat in the enforced direction
	if(mEnforcedDirection != -1)
	{
		dir = Normal(vector(rot(0, 1, 0) * mEnforcedDirection));
		force = mPawn.mIsRagdoll ? mRagdollPushForce : mPushForce;
		if(mPawn.mIsRagdoll)
		{
			mPawn.mesh.AddImpulse( dir * force , , , false );
		}
		else
		{
			oldPhys = mPawn.Physics;
			if(oldPhys == PHYS_Falling)
			{
				force = mPushForce / 8.f;
			}
			mPawn.HandleMomentum( dir * force, mPawn.Location, class'GGDamageTypeAbility' );
			mPawn.SetPhysics(oldPhys);
		}
	}
}

function BeBrainwashed()
{
	local GGAIController aiContr;
	local PlayerController playerContr;
	local int action;
	local GGPlayerInputGame localInput;

	aiContr = GGAIController(mPawn.Controller);
	playerContr = PlayerController(mPawn.Controller);
	localInput = playerContr != none ? GGPlayerInputGame( playerContr.PlayerInput ) : none;
	if(playerContr != none)
	{
		//WorldInfo.Game.Broadcast(self, "aBaseY=" $ localInput.aBaseY);
		//WorldInfo.Game.Broadcast(self, "aStrafe=" $ localInput.aStrafe);
		action = mEnforcedDirection == -1 ? 5 : Rand(6);
		switch(action)
		{
			case 0:
				//Attack
				if(mGoat != none && localInput != none && !mPawn.mIsRagdoll)
				{
					//WorldInfo.Game.Broadcast(self, "force attack");
					localInput.Attack(Rand(2) == 0 ? EAT_Horn : EAT_Kick);
					break;
				}
			case 1:
				//Lick
				if(mGoat != none && localInput != none && !mPawn.mIsRagdoll)
				{
					//WorldInfo.Game.Broadcast(self, "force lick");
					localInput.Attack(EAT_Bite);
					break;
				}
			case 2:
				//Ragdoll
				if(!mPawn.mIsRagdoll)
				{
					//WorldInfo.Game.Broadcast(self, "force ragdoll");
					mPawn.SetRagdoll(true);
					break;
				}
			case 3:
				// Baaa
				if(mGoat != none && !mGoat.IsTimerActive( 'StopBaa' ) && !mGoat.IsInState( 'AbilityBite' ) && !mGoat.IsInState( 'AbilityHorn' ) && !mGoat.IsInState( 'AbilityKick' ))
				{
					//WorldInfo.Game.Broadcast(self, "force baa");
					mGoat.PlayBaa();
					break;
				}
			case 4:
				//Jump
				if(!mPawn.mIsRagdoll)
				{
					//WorldInfo.Game.Broadcast(self, "force jump");
					if(mPawn.DoJump(false))
					{
						break;
					}
				}
				else if (mGoat != none)
				{
					//WorldInfo.Game.Broadcast(self, "force ragdoll jump");
					mGoat.DoRagdollJump();
					break;
				}
			case 5:
				//Go to a random direction (angle)
				mEnforcedDirection=Rand(65536);
				//WorldInfo.Game.Broadcast(self, "force move to " $ mEnforcedDirection);
				break;
		}
	}
	else
	{
		switch(Rand(5))
		{
			case 0:
				//Panic
				if(aiContr != none && aiContr.CanPanic() && !mPawn.mIsRagdoll)
				{
					aiContr.mLastSeenGoat=none;
					aiContr.Panic();
					break;
				}
			case 1:
				//Applaud
				if(aiContr != none && aiContr.CanPawnInteract() && mNpc != none && mNpc.mApplaudAndNoticeGoat && !mPawn.mIsRagdoll)
				{
					aiContr.ApplaudGoat();
					break;
				}
			case 2:
				//Animate
				if(mNpc != none && !mPawn.mIsRagdoll)
				{
					mNpc.SetAnimationInfoStruct( mAnimations[Rand(mAnimations.Length)] );
					break;
				}
			case 3:
				//Make sound
				if(mNpc != none)
				{
					mNpc.PlaySound( mSounds[Rand(mSounds.Length)] );
					break;
				}
			case 4:
				//Ragdoll
				if(mPawn.CanRagdoll(true))
				{
					mPawn.SetRagdoll(true);
					break;
				}
		}
	}
}

function SelfDestroy()
{
	if(!mDestroyed)
	{
		Destroy();
	}
}

event Destroyed()
{
	mDestroyed = true;

	if(mBrainwashPSC != None)
	{
		WorldInfo.MyEmitterPool.OnParticleSystemFinished(mBrainwashPSC);
		mBrainwashPSC.DeactivateSystem();
		mBrainwashPSC = None;
	}

	if( mBrainwashHypnotisedComp != none )
	{
		mBrainwashHypnotisedComp.FadeOut( 0.4f, 0 );
		mBrainwashHypnotisedComp = none;
	}

	if(mPawn != none)
	{
		if(GGAIController(mPawn.Controller) != none)
		{
			GGAIController(mPawn.Controller).ReturnToOriginalPosition();
		}
		else if(mNpc != none)
		{
			mNpc.SetAnimationInfoStruct(mNpc.mDefaultAnimationInfo);
		}
	}

	if(myMut != none)
	{
		myMut.OnBrainwashEnded(mPawn);
	}

	super.Destroyed();
}

DefaultProperties
{
	bBlockActors=false
	bCollideActors=false
	Physics=PHYS_None
	CollisionType=COLLIDE_NoCollision
	bIgnoreBaseRotation=true

	mEnforcedDirection=-1
	mPushForce=100.f
	mRagdollPushForce=500.f
	mBrainwashDuration=30.f
	mBrainwashEffectDelay=2.f
	mBrainwashTemplate=ParticleSystem'Zombie_Particles.Particles.MindControl_ParticleSystem'
	mBrainwashHypnotisedSound=SoundCue'Zombie_NPC_Sound.Hypnotised.Zombie_Hypnotised_Cue'
}