class GGNpcInvader extends GGNpc;

var StaticMeshComponent mHeadMesh;
var array< MaterialInstanceConstant > mSkins;

function InitInvader()
{
	mesh.AttachComponent(mHeadMesh, 'Head');
	mHeadMesh.SetLightEnvironment( mesh.lightenvironment );

	// Give alien a random material
	mesh.SetMaterial(0,  mSkins[Rand(mSkins.Length)]);

	if(Controller == none)
	{
		SpawnDefaultController();
	}

	SetPhysics( PHYS_Falling );
}

simulated event Destroyed()
{
	local GGAIController aiContr;

	aiContr = GGAIController(Controller);
	if(aiContr != none)
	{
		aiContr.UnPossess();
		aiContr.Destroy();
	}

	super.Destroyed();
}

//Nope
function MakeGoatBaa();

DefaultProperties
{
	ControllerClass=class'GGAIControllerInvader'

	Begin Object name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Human_Characters.mesh.Alien_01',
		AnimSets(0)=AnimSet'Heist_Characters_01.Anim.Heist_Characters_Anim_01',
		AnimTreeTemplate=AnimTree'Heist_Characters_01.Anim.Heist_Characters_AnimTree',
		PhysicsAsset=PhysicsAsset'Characters.mesh.CasualGirl_Physics_01',
		Translation=(Z=-85.f)
	End Object
	mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Human_Characters.Textures.Alien_Head'
		Scale3D=(X=1.2f, Y=1.2f, Z=1.2f)
		Translation=(X=0, Y=0, Z=10)
		Rotation=(Pitch=0, Yaw=-16384, Roll=0)
	End Object
	mHeadMesh=StaticMeshComp1

	Begin Object name=CollisionCylinder
		CollisionRadius=25.0f
		CollisionHeight=85.0f
		CollideActors=true
		BlockActors=true
		BlockRigidBody=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
	End Object

	mDefaultAnimationInfo=(AnimationNames=(Idle_01,Idle_02),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true)
	mDanceAnimationInfo=(AnimationNames=(Partyboy),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true)
	mPanicAtWallAnimationInfo=(AnimationNames=(Scared),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true)
	mPanicAnimationInfo=(AnimationNames=(Run, Sprintburning),AnimationRate=1.0f,MovementSpeed=700.0f,LoopAnimation=true,SoundToPlay=())
	mAttackAnimationInfo=(AnimationNames=(Kick),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=false)
	mAngryAnimationInfo=(AnimationNames=(Angry_01,Angry_02,Protesting_01),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true,SoundToPlay=())
	mIdleAnimationInfo=(AnimationNames=(Idle_01,Idle_02),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true)
	mApplaudAnimationInfo=(AnimationNames=(Partyboy,likeitshot,likeitshot2,clap),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=false,SoundToPlay=())
	mRunAnimationInfo=(AnimationNames=(Run),AnimationRate=1.0f,MovementSpeed=700.0f,LoopAnimation=true);
	mNoticeGoatAnimationInfo=(AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=false,SoundToPlay=())
	mIdleSittingAnimationInfo=(AnimationNames=(ChairIdlePointing),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true)

	mKnockedOverSounds=(SoundCue'Space_NPC_Sounds.KnockedOver.NPCSpace_VO_Female_KnockedOver_Cue')

	mNoticeGoatSounds=(SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Female_Notice_Cue', SoundCue'Goat_Sound_NPC.Cue.NPC_Female_notice', SoundCue'Goat_Sound_NPC.Cue.NPC_Female_2_notice', SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Male_Notice_Cue', SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Male_2_Notice_Cue', SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Male_3_Notice_Cue', SoundCue'Goat_Sound_NPC.Cue.NPC_male_notice', SoundCue'Goat_Sound_NPC.Cue.NPC_male_2_notice')
	mAngrySounds=(SoundCue'Space_NPC_Sounds.Angry.NPCSpace_VO_Female_Angry_Cue', SoundCue'Goat_Sound_NPC.Cue.NPC_Female_angry', SoundCue'Goat_Sound_NPC.Cue.NPC_Female_2_angry', SoundCue'Space_NPC_Sounds.Angry.NPCSpace_VO_Male_Angry_Cue', SoundCue'Space_NPC_Sounds.Angry.NPCSpace_VO_Male_3_Angry_Cue', SoundCue'Goat_Sound_NPC.Cue.NPC_Male_angry', SoundCue'Goat_Sound_NPC.Cue.NPC_Male_2_angry')
	mApplaudSounds=(SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Female_Notice_Cue', SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Male_Notice_Cue', SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Male_2_Notice_Cue', SoundCue'Space_NPC_Sounds.Notice.NPCSpace_VO_Male_3_Notice_Cue')
	mPanicSounds=(SoundCue'Space_NPC_Sounds.Panic.NPCSpace_VO_Female_Panic_Cue', SoundCue'Goat_Sound_NPC.Cue.Scream_Female_Cue', SoundCue'Space_NPC_Sounds.Panic.NPCSpace_VO_Male_Panic_Cue', SoundCue'Space_NPC_Sounds.Panic.NPCSpace_VO_Male_2_Panic_Cue', SoundCue'Space_NPC_Sounds.Panic.NPCSpace_VO_Male_3_Panic_Cue', SoundCue'Goat_Sound_NPC.Cue.Scream_Male_Cue')
	mAllKnockedOverSounds=(SoundCue'Space_NPC_Sounds.KnockedOver.NPCSpace_VO_Female_KnockedOver_Cue', SoundCue'Goat_Sound_NPC.Cue.NPC_Female_knocked_over', SoundCue'Goat_Sound_NPC.Cue.NPC_Female_2_knocked_over', SoundCue'Goat_Sound_NPC.Cue.Hurt_Female_Cue', SoundCue'Space_NPC_Sounds.KnockedOver.NPCSpace_VO_Male_KnockedOver_Cue', SoundCue'Space_NPC_Sounds.KnockedOver.NPCSpace_VO_Male_2_KnockedOver_Cue', SoundCue'Space_NPC_Sounds.KnockedOver.NPCSpace_VO_Male_3_KnockedOver_Cue', SoundCue'Goat_Sound_NPC.Cue.NPC_male_knocked_over', SoundCue'Goat_Sound_NPC.Cue.NPC_male_2_knocked_over', SoundCue'Goat_Sound_NPC.Cue.Hurt_Male_Cue')

	mAutoSetReactionSounds=true

	mCanPanic=false
	mNPCSoundEnabled=false

	SightRadius=1500.0f
	HearingThreshold=1500.0f

	MaxJumpHeight=250

	mStandUpDelay=1.f

	mAttackRange=200.0f;
	mAttackMomentum=1000.0f

	mTimesKnockedByGoatStayDownLimit=1000000

	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Bob_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Cindy_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_DarfTheVader_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Ford_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Rasmus_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Sven-Benny_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Tyrone_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Vlad_INST')
	mSkins.Add(MaterialInstanceConstant'Human_Characters.Materials.Alien_Walter_INST')
}