
var cmd = newArray("Adjust Image", "Wavenumber","Scale Bar","Draw","-","Collect Data From ImageSet","-", "Import Text Image");
var menu = newMenu("Print Menu Tool", cmd);

macro "Print Menu Tool - C00fT0f18P" {
	lable = getArgument();

		CorrectImage();
	if (lable=="Wavenumber")
		PrintWavenumber();	
	else if (lable=="Scale Bar")
		PrintScaleBar();
	else if (lable=="Import Text Image")
		run("Text Image... ", "open");
	else if (lable=="Adjust Image"){
			CorrectImage();}
	else if (lable=="Draw")
		run("Add Selection...");
	else if (lable=="Collect Data From ImageSet")
		CollectData();
	else if (lable!="-")
		run(lable);

}

var min,max,nStep=0,step,CrystalAmount,beckgr,addtext;

function CollectData() {

// Import and Adjust Images	
	SetParameters ();
	ImportTextImage ();
	AdjustImages ();


	run("Images to Stack", "name=Stack title=[] use keep");
	run("Z Project...", "projection=[Average Intensity]");
	run("Fire");
	selectWindow("Stack");
	close();
	
	for (i = min; i < max; i=i+step) 
		nStep++;

		Xvalues=newArray(nStep);
	for (i = 0; i < nStep; i++) {
		Xvalues[i]=min+step*i;
	}

	profileCr1=newArray(nStep);
	if (CrystalAmount==2) profileCr2=newArray(nStep);
	backgroundArray=newArray(nStep);
	
// Measure
	for (i = 1; i <= CrystalAmount; i++) 
		TakeSelection (i,"Crystal");
		
	if (beckgr==true)
			TakeSelection (" ","Background");	
// Put Crystal 1 values into array
	for (i = 0; i < nStep; i++) {
		selectWindow("Crystal 1");
		profileCr1[i]=getResult("Mean", i);
		}
		
// Put Crystal 2 values into array
	if (CrystalAmount==2){
			for (i = 0; i < nStep; i++) {
		selectWindow("Crystal 2");
		profileCr2[i]=getResult("Mean", i);}
		}
			
// Assign Background values into array
	for (i = 0; i < nStep; i++) {
			selectWindow("Background  ");
			backgroundArray[i]=getResult("Mean", i);
		}
			
// Substract Background
	for (i = 0; i < nStep; i++) {
		for (j = 0; j < nStep; j++) {
			if(i==j) profileCr1[i]=profileCr1[i]-backgroundArray[j];
			if(i==j && CrystalAmount==2) profileCr2[i]=profileCr2[i]-backgroundArray[j];
		}}
			
// Create Plot
		run("Close All");
		Array.getStatistics(profileCr1, min1, max1, mean1, sdev1);
		if (CrystalAmount==2){
			Array.getStatistics(profileCr2, min2, max2, mean2, sdev2);
			maxx=maxOf(max1, max2);
			minn=minOf(min1, min2);}
		else {
			minn=min1;
			maxx=max1;
		}
		Plot.create("Simple Plot", "Angle", "Intensity", Xvalues , profileCr1);
		Plot.addText("A line of text", 0, 0);
		Plot.setLimits(min* 1.05, max * 1.05, minn * 0.95, maxx * 1.05);
		if (CrystalAmount==2) Plot.add("connected circle", Xvalues, profileCr2);
		Plot.setLegend("First Crystal\tSecond Crystal");
        setJustification("center");
        setJustification("right");
        setJustification("left");	
}


function TakeSelection(CCo,text){
	do {
		selectWindow("AVG_Stack");
		waitForUser("Select Area", "Select Area of "+text+" "+CCo+" and click OK");
		type=selectionType();
	} while (type==-1);
	getSelectionBounds(x, y, w, h);
	laso (x, y, w , h);
	selectWindow("Results");

	Table.rename("Results", text+" "+ CCo);
	}

function laso (x,y,w,h) {
	for (i=min; i<=max; i=i+step)
{
		selectWindow(addtext+i);
		makeOval(x, y, w, h);
		run("Measure");
		run("Add Selection...");
}
}

function ImportTextImage () {
  dir = getDirectory("Choose directory");
  list = getFileList(dir);
  run("Close All");
  setBatchMode(true);
  for (i=0; i<list.length; i++) {
     file = dir + list[i];
     run("Text Image... ", "open=&file");
  }
  	run("Images to Stack", "use");
  
	selectWindow("Stack"); 
	setBatchMode(false);
	run("Stack to Images");
}

function SetParameters () {
  Dialog.create("Input Min and Max angles");
  Dialog.addMessage("Set parameters of the measurement:\n  -min angle, max angle, step, number of crystals on a single image;\n  -if necessary, add text in filenames before a value of an angle;")
  Dialog.addNumber("min:", -180);
  Dialog.addNumber("max:", 180);
  Dialog.addNumber("step:", 10);
  Dialog.addChoice ("Number of crystals:", newArray("1","2"),"1");
  Dialog.addCheckbox("Backround", true);
  Dialog.addString("Filename text before an ANGLE:", "");
  
  Dialog.show();
  min= Dialog.getNumber();
  max = Dialog.getNumber();
  step = Dialog.getNumber();
  CrystalAmount = Dialog.getChoice();
  beckgr= Dialog.getCheckbox();
  addtext= Dialog.getString();
}

function PrintScaleBar(){

filename = getTitle();
	index2=indexOf(filename, "um_");
	index1=index2-1;
	tempIndex=index1;
	if(index1<0 || index2 <0) 
		exit("Wrong title pattern");

	searcher=substring(filename, index1, index2);

	while (searcher!="x"){

	searcher=substring(filename, tempIndex, tempIndex+1);
		tempIndex--;
	}
	index1=tempIndex+2;
	text=substring(filename, index1, index2);
	length=parseInt(text);
	run("Set Scale...", "distance=1000 known=length unit=um");
	run("Scale Bar...");
}

function PrintWavenumber(){
	filename = getTitle();
	index2=indexOf(filename, "cm-1");
	index1=index2-1;
	tempIndex=index1;
	searcher=substring(filename, index1, index2);

	while (tempIndex>=0 && searcher!="_"){
	searcher=substring(filename, tempIndex, tempIndex+1);
		tempIndex--;
	}
	if 	(searcher=="_") tempIndex++;
	index1=tempIndex+1;
	if(index1<0 || index2 <0) 
		exit("Wrong title pattern");
	text=substring(filename, index1, index2);
		setFont("SansSerif", 50, " antialiased");
		drawString(text+" 1/cm", 20, 990);
	}
function AdjustImages () {
	for (i = min; i <= max; i=i+step) {
		selectWindow(addtext+i);
		run("Size...", "width=1000 height=1000 constrain average interpolation=None");
		run("Flip Horizontally");
		run("Fire");
}}
	
function CorrectImage() {
	if(isOpen(1)){
	getDimensions(width, height, channels, slices, frames);
	if (width!=1000) {
	run("Size...", "width=1000 height=1000 constrain average interpolation=None");
	run("Flip Horizontally");
	run("Fire");
	}}}
