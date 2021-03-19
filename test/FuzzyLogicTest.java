import java.util.*;
import java.lang.Math;

public class FuzzyLogicTest {

    public static double count_to_one(double N){
      
        double sum=0;
        for(int i=0;i<N;i++ ){
            sum = sum+(1/(double)N);
        }
        return sum;
    }

    public static double complext_function(double in, int n){
        double x = in;
        for(int i=0;i<n;i++ ){
            x = (3 * Math.pow(x, 4) - 20 * Math.pow(x, 3) +35*Math.pow(x, 2)-24)/
            		(double)(4*Math.pow(x, 3)-30*Math.pow(x,2) +70*x-50);
        }
        return x;
    }

    
    public static double complext_function_2( int n){
    	double u0 = 2;
    	double u1 = -4;
    	ArrayList<Double> array_x = new ArrayList<Double>();
    			array_x.add(0,u0);
    			array_x.add(1,u1);
    					int i;
    			        for( i=2;i<n+2;i++ ){
    						array_x.add(i,111 - (1130/(double)array_x.get(i-1)) + (3000/(array_x.get(i-1) * array_x.get(i-2))));
    			            System.out.println(i + " "+ array_x.get(i));
    			        }
    			        return array_x.get(i-1);
    }
    

    public static void main(String args[]){
    Scanner sc =new Scanner(System.in);
    int number = Integer.parseInt(sc.nextLine());
    System.out.println("Actual input is "+number);
    System.out.println("Expected output is 1");
    System.out.println("Computed result for input is "+count_to_one(number));
    
    double number1 = Double.parseDouble(sc.nextLine());
    System.out.println("Actual input is "+number1);
    System.out.println("Expected output is 1");//1.5100050721319
    System.out.println("Computed result for input is "+complext_function(number1,30));
    
    
    int number2 = Integer.parseInt(sc.nextLine());
    System.out.println("Computed result for input is "+complext_function_2(number2));
    
    }
}