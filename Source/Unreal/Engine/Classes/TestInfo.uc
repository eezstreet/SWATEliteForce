//=============================================================================
// For internal testing.
//=============================================================================
class TestInfo extends Info;

var() bool bTrue1;
var() bool bFalse1;
var() bool bTrue2;
var() bool bFalse2;
var bool bBool1;
var bool bBool2;
var() int xnum;
var float ppp;
var string sxx;
var int MyArray[2];
var vector v1,v2;
var string TestRepStr;
//var string[32] teststring;

const Pie=3.14;
const Str="Tim";
const Lotus=vect(1,2,3);

var struct STest
{
	var bool b1;
	var int i;
	var bool b2;
	var bool b3;
} ST;

function TestQ()
{
	local vector v;
	v.x = 2;
	v.y = 3;
	v.z = 4;
	assert(v==vect(2,3,4));
	assert(v.z==4);
	assert(v.y==3);
	assert(v.x==2);
}

static function test()
{
	class'testinfo'.default.v1 = vect(1,2,3);
}

function PostBeginPlay()
{
	log("!!BEGIN");

	default.v1=vect(5,4,3);
	assert(default.v1==vect(5,4,3));
	test();
	assert(default.v1==vect(1,2,3));

	assert(IsA('Actor'));
	assert(IsA('TestInfo'));
	assert(IsA('Info'));
	assert(!IsA('LevelInfo'));
	assert(!IsA('Texture'));
	//o=dynamicloadobject( "UnrealShare.AutoMag.Reload", class'object' );
	//assert(o!=None);
	//assert(o==None);
	log("!!END");
}

function TestStructBools()
{
	assert(ST.b1==false);
	assert(ST.b2==false);
	assert(ST.b3==false);

	ST.b1=true;
	assert(ST.b1==true);
	assert(ST.b2==false);
	assert(ST.b3==false);

	ST.b2=true;
	assert(ST.b1==true);
	assert(ST.b2==true);
	assert(ST.b3==false);

	ST.b3=true;
	assert(ST.b1==true);
	assert(ST.b2==true);
	assert(ST.b3==true);

	ST.b1=false;
	ST.b2=false;
	ST.b3=false;
}

function BeginPlay()
{
	local testobj to;

	to = new class'TestObj';
	to = new()class'TestObj';
	to = new(self)class'TestObj';
	to = new(self,"")class'TestObj';
	to = new(self,"",0)class'TestObj';
	to.Test();
	TestStructBools();
}

function TestX( bool bResource )
{
	local int n;
	n = int(bResource);
	MyArray[ int(bResource) ] = 0;
	MyArray[ int(bResource) ]++;
}

function bool RecurseTest()
{
	bBool1=true;
	return false;
}

function TestLimitor( class c )
{
	local class<actor> NewClass;
	NewClass = class<actor>( c );
}

static function int OtherStatic( int i )
{
	assert(i==246);
	assert(default.xnum==777);
	return 555;
}

static function int TestStatic( int i )
{
	assert(i==123);
	assert(default.xnum==777);
	assert(OtherStatic(i*2)==555);
	return i;
}

function TestContinueFor()
{
	local int i;
	log("TestContinue");
	for( i=0; i<20; i++ )
	{
		log("iteration "$i);
		if(i==7||i==9||i==19)
			continue;
		log("...");
	}
	log("DoneContinue");
}

function TestContinueWhile()
{
	local int i;
	log("TestContinue");
	while( ++i <= 20 )
	{
		log("iteration "$i);
		if(i==7||i==9)
			continue;
		log("...");
	}
	log("DoneContinue");
}

function TestContinueDoUntil()
{
	local int i;
	log("TestContinue");
	do
	{
		i++;
		log("iteration "$i);
		if(i==7||i==9||i>18)
			continue;
		log("...");
	} until( i>20 );
	log("DoneContinue");
}

function TestContinueForEach()
{
	local actor a;
	log("TestContinue");
	foreach AllActors( class'Actor', a )
	{
		log("actor "$a);
		if(light(a)==none)
			continue;
		log("...");
	}
	log("DoneContinue");
}


function SubTestOptionalOut( optional out int a, optional out int b, optional out int c )
{
	a *= 2;
	b = b*2;
	c += c;
}
function TestOptionalOut()
{
	local int a,b,c;
	a=1; b=2; c=3;

	SubTestOptionalOut(a,b,c);
	assert(a==2); assert(b==4); assert(c==6);

	SubTestOptionalOut(a,b);
	assert(a==4); assert(b==8); assert(c==6);

	SubTestOptionalOut(,b,c);
	assert(a==4); assert(b==16); assert(c==12);

	SubTestOptionalOut();
	assert(a==4); assert(b==16); assert(c==12);

	SubTestOptionalOut(a,b,c);
	assert(a==8); assert(b==32); assert(c==24);

	log("TestOptionalOut ok!");
}

function TestNullContext( actor a )
{
	bHidden = a.bHidden;
	a.bHidden = bHidden;
}

function TestSwitch()
{
	local string s;
	local int i;
	local bool b;
	s="Tim";
	i=2;
	switch( i )
	{
		case 0:
			assert(false);
			break;
		case 2:
			b=true;
			break;
		default:
			assert(false);
			break;
	}
	assert(b);
	switch( s )
	{
		case "":
			assert(false);
			break;
		case "xyzzy":
			assert(false);
			break;
		default:
			b=false;
			break;
	}
	assert(!b);
	log("testswitch succeeded");
}

function Tick( float DeltaTime )
{
	local class C;
	local class<testinfo> TC;

	log("time="$Level.TimeSeconds);

	TestOptionalOut();
	TestNullContext( self );
	TestNullContext( None );
	TestSwitch();

	v1=vect(1,2,3);
	v2=vect(2,4,6);
	assert(v1!=v2);
	assert(!(v1==v2));
	assert(v1==vect(1,2,3));
	assert(v2==vect(2,4,6));
	assert(vect(1,2,5)!=v1);
	assert(v1*2==v2);
	assert(v1==v2/2);

	assert(Pie==3.14);
	assert(Pie!=2);
	assert(Str=="Tim");
	assert(Str!="Bob");
	assert(Lotus==vect(1,2,3));

	assert(GetPropertyText("sxx")=="Tim");
	assert(GetPropertyText("ppp")!="123");
	assert(GetPropertyText("bogus")=="");
	xnum=345;
	assert(GetPropertyText("xnum")=="345");
	SetPropertyText("xnum","999");
	assert(xnum==999);
	assert(xnum!=666);

	assert(bTrue1==true);
	assert(bFalse1==false);
	assert(bTrue2==true);
	assert(bFalse2==false);

	assert(default.bTrue1==true);
	assert(default.bFalse1==false);
	assert(default.bTrue2==true);
	assert(default.bFalse2==false);

	assert(class'TestInfo'.default.bTrue1==true);
	assert(class'TestInfo'.default.bFalse1==false);
	assert(class'TestInfo'.default.bTrue2==true);
	assert(class'TestInfo'.default.bFalse2==false);

	TC=Class;
	assert(TC.default.bTrue1==true);
	assert(TC.default.bFalse1==false);
	assert(TC.default.bTrue2==true);
	assert(TC.default.bFalse2==false);

	C=Class;
	assert(class<testinfo>(C).default.bTrue1==true);
	assert(class<testinfo>(C).default.bFalse1==false);
	assert(class<testinfo>(C).default.bTrue2==true);
	assert(class<testinfo>(C).default.bFalse2==false);

	assert(default.xnum==777);
	TestStatic(123);
	TC.static.TestStatic(123);
	class<testinfo>(C).static.TestStatic(123);

	bBool2=RecurseTest();
	assert(bBool2==false);

	TestStructBools();
	TestQ();

	log( "All tests passed" );
}

function f();

function temp()
{
	temp();
}

state AA
{
	function f();
}
state BB
{
	function f();
}
state CCAA extends AA
{
	function f();
}
state DDAA extends AA
{
	function f();
}
state EEDDAA extends DDAA
{
	function f();
}

defaultproperties
{
	bTrue1=true
	bTrue2=true
	bHidden=false
	sxx="Tim"
	ppp=3.14
	xnum=777
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
