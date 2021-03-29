import ballerina/io;
import ballerina/http;

public function main() {
    error? result = executeWorkers();
    executeStartAction(); 
}

// Create two new strands. Ballerina runtime assigns the first one to a separate thread and assigns
// the second one to the same thread executing the current strand.
public function executeStartAction() {
    io:println("--- case 4 ---");
    future<int> f1 = @strand {thread: "any"} start multiply(1, 2);
    future<int[]> f2 = start createArray();

    io:println("Before the wait action");
    var results = wait {f1, f2};
    io:println("After the wait action\n");
}

function multiply(int x, int y) returns int {
    io:println(string `Multiplying ${x} * ${y}`);
    return x * y;
}

function createArray() returns int[] {
    int[] a = [];
    foreach int i in 0 ... 10000 {
        a[i] = i;
    }
    return a;
}

// The code outside the named workers belongs to an implicit 
// default worker. The default worker in each function wil be 
// executed in the same strand as the caller function.
public function executeWorkers() returns error? {
    io:println("Worker execution started");

    // This block belongs to the `w1` worker.
    worker w1 returns error? {
        http:Client httpClient = check new ("https://api.mathjs.org");
        string response = <string>check httpClient->get("/v4/?expr=2*3", targetType = string);
        io:println("Worker 1 response: ", response);
    }

    worker w2 returns error? {
        http:Client httpClient = check new ("https://api.mathjs.org");
        string response = <string>check httpClient->get("/v4/?expr=5*7", targetType = string);
        io:println("Worker 2 response: ", response);
    }

    // Wait for both workers to finish.
    record { error? w1; error? w2; } result = wait {w1, w2};

    io:println("Worker execution finished: ", result);
}
