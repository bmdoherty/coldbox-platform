﻿<cfcomponent extends="coldbox.system.testing.BaseTestCase">
<cfscript>
	this.loadColdBox = false;

	function setup(){
		// init with defaults
		injector = getMockBox().createMock("coldbox.system.ioc.Injector").init("coldbox.tests.specs.ioc.config.samples.InjectorCreationTestsBinder");
		application.wirebox = injector;
		// mock logger
		mockLogger = getMockBox().createEmptyMock("coldbox.system.logging.Logger").$("canDebug",true).$("debug").$("error");
		injector.$property("log","instance",mockLogger);
		// mock event manager
		getMockBox().prepareMock( injector.getEventManager() );
		mockStub = createStub();
	}

	function teardown(){
		structDelete(application, "wirebox");
		super.teardown();
	}

	function testMixins(){
		r = injector.getInstance("MixinTest");
		assertEquals( "lui", r.myEcho("lui") );
		assertEquals( "lui", r.myEcho2("lui") );
	}

	function testSetters(){
		r = injector.getInstance("CategoryService");
		debug( r );
	}

	function testLocateInstance(){
		// Locate by package scan
		r = injector.locateInstance("ioc.category.CategoryBean");
		assertEquals("coldbox.test-harness.models.ioc.category.CategoryBean", r);

		// Locate Not Found
		r = injector.locateInstance("com.com.com.Whatever");
		assertEquals('', r);

		// Locate by Full Path
		r = injector.locateInstance("coldbox.system.EventHandler");
		assertEquals("coldbox.system.EventHandler", r);
	}

	function testbuildInstance(){
		//mapping
		mapping = getMockBox().createMock("coldbox.system.ioc.config.Mapping").init("MyTest");
		// mocks
		mockBuilder = getMockBox().createMock("coldbox.system.ioc.Builder").init( injector );
		injector.$property("builder","instance",mockBuilder);
		injector.getEventManager().$("process");
		mockStub = getMockbox().createStub();

		// CFC
		mapping.setType("cfc");
		mockBuilder.$("buildCFC", mockStub);
		val = injector.buildInstance( mapping );
		assertEquals(mockStub, val);

		// JAVA
		mapping.setType("java");
		mockBuilder.$("buildJavaClass", mockStub);
		val = injector.buildInstance( mapping );
		assertEquals(mockStub, val);

		// Webservice
		mapping.setType("webservice");
		mockBuilder.$("buildWebService", mockStub);
		val = injector.buildInstance( mapping );
		assertEquals(mockStub, val);

		// Feed
		mapping.setType("rss");
		mockBuilder.$("buildFeed", mockStub);
		val = injector.buildInstance( mapping );
		assertEquals(mockStub, val);

		// Constant
		mapping.setType("constant").setValue("testbaby");
		val = injector.buildInstance( mapping );
		assertEquals("testbaby", val);

		// Provider
		mockProvider = getMockBox().createEmptyMock("coldbox.system.ioc.Provider").$("get",mockStub);
		mapping.setType("provider").setPath("MyCoolProvider");
		injector.$("getInstance").$args("MyCoolProvider").$results(mockProvider);
		val = injector.buildInstance( mapping );
		assertEquals(mockStub, val);
		// Provider closure
		mapping.setType("provider").setPath( variables.providerUDF );
		val = injector.buildInstance( mapping );
		assertTrue( val.verify() );

	}

	function providerUDF(){
		return new testbox.system.MockBox().createStub().$("verify", true);
	}

	function testProviderMethods(){
		// skip for railo as they don't have the context method
		if( listFindNoCase( "Railo,Lucee", server.coldfusion.productname ) ){ return; }

		providerTest = injector.getInstance("ProviderTest");
		assertEquals( true, isObject(providerTest.getPizza()) );
		assertEquals( true, structKeyExists(session,"wirebox:pizza") );
		assertEquals( "coldbox.system.ioc.Provider", getMetadata(providerTest.coolPizza).name);
		assertEquals( session["wirebox:pizza"], providerTest.coolPizza.get() );
		structclear(session);
	}

	/*
	function testGoogleNews(){
		gnews = injector.getInstance("googleNews");
		assertEquals(true, structKeyExists(gnews, "items") );
		assertEquals(true, structKeyExists(gnews, "metadata") );
		assertEquals( true, injector.getCacheBox().getDefaultCache().lookup('wirebox:googlenews') );
	}
	*/

	function testJava(){
		buffer = injector.getInstance("stringBuffer");
		assertEquals( "java.lang.StringBuffer", getMetadata(buffer).name );
	}

	function testConstant(){
		prop = injector.getInstance("jsonProperty");
		assertTrue( len(prop) );
	}

	function testWebService(){
		ws = injector.getInstance("coldboxWS");

		// Railo
		if( listFindNoCase( "Railo,Lucee", server.coldfusion.productname ) ){
			expect(	getMetadata(ws).name  ).toMatch( "rpc" );
		}
		// adobe
		else{
			expect( getMetadata( ws ).name ).toMatch( "ServiceProxy" );
		}
	}

	function testDSL(){
		dslobject = injector.getInstance("coolDSL");

		assertEquals("root", dslObject.getCategory() );
	}

	function testFactoryBeans(){
		b1 = injector.getInstance("factoryBean1");

		assertEquals( "luis", b1.name );
		assertEquals( true, b1.cool );

		b2 = injector.getInstance("factoryBean2");
		assertEquals( "alexia", b2.name );
		assertEquals( true, b2.cool );
	}

	function testTImeZone(){
		t = injector.getInstance("calendar");
		t = injector.getInstance("calendar2");
	}

	function testParentMappings(){
		//debug( injector.getBinder().getMapping("concreteService").getMemento() );
		o = injector.getInstance("concreteService");
		assertTrue( isObject( o.getSomeAlphaDAO() ) );
		assertTrue( isObject( o.getSomeBravoDAO() ) );
		assertTrue( isObject( o.getSomeCharlieDAO() ) );
		assertTrue( isObject( o.getSomeDeltaDAO() ) );

	}

	function testScopes(){
		r = injector.getInstance("RequestCategoryBean");
		assertEquals( request["wirebox:RequestCategoryBean"], r );
		r = injector.getInstance("SessionCategoryBean");
		assertEquals( session["wirebox:SessionCategoryBean"], r );
		r = injector.getInstance("ApplicationCategoryBean");
		assertEquals( Application["wirebox:ApplicationCategoryBean"], r );
		r = injector.getInstance("ServerCategoryBean");
		assertEquals( server["wirebox:ServerCategoryBean"], r );
	}

	function testInheritedMetadata(){
		var r = injector.getInstance("ConcreteMetadata");
		//debug( r.getData() );
		assertEquals( injector.getInstance("WireBoxURL"), r.getData() );
	}

	function testImplicitSetters(){
		var c = injector.getInstance("implicitTest");
		//debug( c );
	}

	function testDSLCreation(){
		var c = injector.getInstance(dsl="wirebox");
		expect(	getMetadata( c ).name ).toMatch( "Injector" );
	}

</cfscript>
</cfcomponent>