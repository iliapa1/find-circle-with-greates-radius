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
  public float x, y;
  public float radius;
  
  public Circle(float x, float y, float radius) {
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
abstract class GA {
  public abstract void assignFitness();
  public abstract ArrayList<Circle> rouletteSelect();
  public abstract void mutate();
  public abstract void crossover();
  public abstract void generateFirstGen();
  public abstract void generateNextGen();
  public abstract Circle getFittest();
}

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
  
  public ArrayList<Circle> rouletteSelect() {
    List<Circle> selectedMembers = new ArrayList<Circle>(membersInPopulation);
    List<Float> cumulativeFitness = new ArrayList<Float>();
    cumulativeFitness.add(members.get(0).radius);
    for (int i = 1; i < membersInPopulation; i++) {
      cumulativeFitness.add(members.get(i-1).radius + members.get(i).radius);
    }
    for (int i = 0; i < membersInPopulation; i++) {
      float randomFitness = ThreadLocalRandom.current().nextFloat(0, cumulativeFitness.get(cumulativeFitness.size() - 1));
      int index = Collections.binarySearch(cumulativeFitness, randomFitness);
      if (index < 0) index = Math.abs(index + 1);
      selectedMembers.add(members.get(index));
    }
    return selectedMembers;
  }
  
  public void crossoverCurrentPop() {
    List<Circle> newMembers = new ArrayList<Circle>();
    for (int i = 0; i < this.members.length(); i+=2) {
      if (ThreadLocalRandom.current().nextFloat(0, 1) < crossoverRate) {
        
      }
      else {
        newMembers.add(this.members.get(i));
        newMembers.add(this.members.get(i+1));
      }
      
    }
  }
  
  public void mutateCurrentPop() {
    
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
