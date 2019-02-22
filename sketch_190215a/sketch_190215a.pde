import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

int CANVAS_X = 600;
int CANVAS_Y = 600;

List<Circle> allCircles;

int INITIAL_CIRCLE_COUNT = 14;
int MAX_CIRCLE_RADIUS = 70;
int MIN_CIRCLE_RADIUS = 15;
int STOP_AFTER_GEN = 10000;

void setup() {
  allCircles = new ArrayList<Circle>();
  for (int i = 0; i < INITIAL_CIRCLE_COUNT; i++) {
     RandomNonCollidingCircle temp = new RandomNonCollidingCircle(MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS, allCircles);
     allCircles.add(temp);
   }
}

void settings() {
  size(CANVAS_X, CANVAS_Y);
}


void draw() {
   
   for (Circle c : allCircles) {
      c.draw(); 
   }
}

class Circle {
  public int x, y;
  public int radius;
  
  public Circle(int x, int y, int radius) {
    this.x = x;
    this.y = y;
    this.radius = radius;
  }
  
  public Circle() {
    this.x = 0;
    this.y = 0;
    this.radius = 0;
  }
  
  public void draw() {
    circle(x, y, radius);
  }
  
  public boolean collidesWith(Circle other) {
     return (dist(this.x, this.y, other.x, other.y) < this.radius + other.radius) ? true : false;
  }
  
  public boolean isOutOfBounds() {
     return (this.x + this.radius > CANVAS_X || this.y + this.radius > CANVAS_Y || this.x - this.radius < 0 || this.y - this.radius < 0) ? true : false;
  }
}

class RandomNonCollidingCircle extends Circle {
    public RandomNonCollidingCircle(int minRadius, int maxRadius, List<Circle> allCircles) {
      boolean circleParamsGenerated = false;
      int randRadius = 0, randX = 0, randY = 0;
      while (!circleParamsGenerated) {
        randRadius = ThreadLocalRandom.current().nextInt(minRadius, maxRadius + 1); 
        randX = ThreadLocalRandom.current().nextInt(randRadius, CANVAS_X - randRadius + 1);
        randY = ThreadLocalRandom.current().nextInt(randRadius, CANVAS_X - randRadius + 1);
        circleParamsGenerated = true;
        Circle sampleCircle = new Circle(randX, randY, randRadius);
        for (Circle c : allCircles) {
          if (c.collidesWith(sampleCircle) || sampleCircle.isOutOfBounds()) circleParamsGenerated = false;
        }
      }
      this.x = randX;
      this.y = randY;
      this.radius = randRadius;
    }
}


//Instead of "circle" everywhere, rework this to use a template/generic
//https://docs.oracle.com/javase/tutorial/java/generics/types.html

class OneStageGA {
  public List<Circle> allOtherCircles;
  public List<Circle> members;
  public int membersInPopulation;
  public int generationCounter;
  public float crossoverRate;
  public float mutationRate;
  public int maxRadius;
  
  public OneStageGA(List<Circle> allOtherCircles, int membersInPopulation, float crossoverRate, float mutationRate, int maxRadius) {
    this.allOtherCircles = allOtherCircles;
    this.members = new ArrayList<Circle>(membersInPopulation);
    this.membersInPopulation = membersInPopulation;
    this.generationCounter = 0;
    this.crossoverRate = crossoverRate;
    this.mutationRate = mutationRate;
    this.maxRadius = maxRadius;
  }

  public void generateFirstGen() {
     members.clear();
     for (int i = 0; i < membersInPopulation; i++) {
       members.add(new RandomNonCollidingCircle(1, maxRadius, allOtherCircles));
     }
  }
  
  public void assignFitness() {
    //The radius is the fitness of a member(Circle)
  }
  
  public List<Circle> rouletteSelect() {
    List<Circle> selectedMembers = new ArrayList<Circle>(membersInPopulation);
    List<Integer> cumulativeFitness = new ArrayList<Integer>();
    cumulativeFitness.add(members.get(0).radius);
    for (int i = 1; i < membersInPopulation; i++) {
      cumulativeFitness.add(members.get(i-1).radius + members.get(i).radius);
    }
    for (int i = 0; i < membersInPopulation; i++) {
      int randomFitness = ThreadLocalRandom.current().nextInt(0, cumulativeFitness.get(cumulativeFitness.size() - 1));
      int index = Collections.binarySearch(cumulativeFitness, randomFitness);
      if (index < 0) index = Math.abs(index + 1);
      selectedMembers.add(members.get(index));
    }
    return selectedMembers;
  }
  
  private List<Integer> getParamsOfMember(Circle m) {
    List<Integer> params = new ArrayList<Integer>();
    params.add(m.x);
    params.add(m.y);
    params.add(m.radius);
    return params;
  }
  
  private Circle breed(Circle member1, Circle member2) {
    List<Integer> mem1Params = getParamsOfMember(member1);
    List<Integer> mem2Params = getParamsOfMember(member2);
    List<Integer> newMemParams = new ArrayList<Integer>();
    for (int i = 0; i < mem1Params.size(); i++) {
      String mem1ParamAsStr = String.valueOf(mem1Params.get(i));
      String mem2ParamAsStr = String.valueOf(mem2Params.get(i));
      //Makes the string equal length, filling up the smaller one with 0s to the left
      if (mem1ParamAsStr.length() > mem2ParamAsStr.length()) {
        while (mem1ParamAsStr.length() != mem2ParamAsStr.length()) {
          mem2ParamAsStr = "0" + mem2ParamAsStr; 
        }
      } else {
        while (mem1ParamAsStr.length() != mem2ParamAsStr.length()) {
          mem1ParamAsStr = "0" + mem1ParamAsStr; 
        }
      }
      String newParamAsString = new String();
      for (int j = 0; j < mem1ParamAsStr.length(); j++) {
         newParamAsString = (ThreadLocalRandom.current().nextDouble(1) < 0.5) ? newParamAsString + mem1ParamAsStr.charAt(i) : newParamAsString + mem2ParamAsStr.charAt(i);
      }
      newMemParams.add(Integer.parseInt(newParamAsString));
    }
    return new Circle(newMemParams.get(0), newMemParams.get(1), newMemParams.get(2));
  }
  
  public void crossoverCurrentPop() {
    List<Circle> newMembers = new ArrayList<Circle>();
    for (int i = 0; i < this.members.size(); i+=2) {
      if (ThreadLocalRandom.current().nextDouble(1) < crossoverRate) {
        newMembers.add(breed(this.members.get(i), this.members.get(i+1)));
        newMembers.add(breed(this.members.get(i), this.members.get(i+1)));
      }
      else {
        newMembers.add(this.members.get(i));
        newMembers.add(this.members.get(i+1));
      }
      
    }
  }
  
  public void mutateCurrentPop() {
    for (Circle c : this.members) {
       List<Integer> params = getParamsOfMember(c);
       for (Integer param : params) {
         String paramAsStr = String.valueOf(param);
         for (int i = 0; i < paramAsStr.length(); i++) {
           if (ThreadLocalRandom.current().nextFloat() < this.mutationRate) {
             char[] paramAsChars = paramAsStr.toCharArray();
             paramAsChars[i] = (char) ThreadLocalRandom.current().nextInt(10);
             paramAsStr = String.valueOf(paramAsChars);
           }
         }
         param = Integer.parseInt(paramAsStr);
       }
    }
  }
  
  public void generateNextGen() {
    this.members = rouletteSelect();
    crossoverCurrentPop();
    mutateCurrentPop();
  }
  
  public Circle getFittest() {
    Collections.sort(this.members, new SortByRadius());
    return this.members.get(0);
  }
}

class SortByRadius implements Comparator<Circle> {
  public int compare(Circle a, Circle b) {
    return b.radius - a.radius; 
  }
}
