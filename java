package com.todoapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoApplication.class, args);
    }
}



package com.todoapp;

import java.time.LocalDateTime;

public class Task {
    private Long id;
    private String title;
    private String description;
    private boolean completed;
    private LocalDateTime createdAt;
    
    // Constructors
    public Task() {
        this.createdAt = LocalDateTime.now();
    }
    
    public Task(String title, String description) {
        this();
        this.title = title;
        this.description = description;
        this.completed = false;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public boolean isCompleted() {
        return completed;
    }
    
    public void setCompleted(boolean completed) {
        this.completed = completed;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}






package com.todoapp;

import org.springframework.stereotype.Service;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class TaskService {
    
    private final Map<Long, Task> tasks = new HashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);
    
    // Constructor - Add some sample data
    public TaskService() {
        Task task1 = new Task("Learn Spring Boot", "Complete the tutorial");
        task1.setId(idGenerator.getAndIncrement());
        tasks.put(task1.getId(), task1);
        
        Task task2 = new Task("Build REST API", "Create a todo application");
        task2.setId(idGenerator.getAndIncrement());
        tasks.put(task2.getId(), task2);
    }
    
    // Get all tasks
    public List<Task> getAllTasks() {
        return new ArrayList<>(tasks.values());
    }
    
    // Get task by ID
    public Optional<Task> getTaskById(Long id) {
        return Optional.ofNullable(tasks.get(id));
    }
    
    // Create new task
    public Task createTask(Task task) {
        task.setId(idGenerator.getAndIncrement());
        tasks.put(task.getId(), task);
        return task;
    }
    
    // Update existing task
    public Optional<Task> updateTask(Long id, Task updatedTask) {
        if (tasks.containsKey(id)) {
            updatedTask.setId(id);
            tasks.put(id, updatedTask);
            return Optional.of(updatedTask);
        }
        return Optional.empty();
    }
    
    // Delete task
    public boolean deleteTask(Long id) {
        return tasks.remove(id) != null;
    }
    
    // Mark task as completed
    public Optional<Task> markAsCompleted(Long id) {
        Task task = tasks.get(id);
        if (task != null) {
            task.setCompleted(true);
            return Optional.of(task);
        }
        return Optional.empty();
    }
    
    // Get completed tasks
    public List<Task> getCompletedTasks() {
        return tasks.values().stream()
                .filter(Task::isCompleted)
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
    }
    
    // Get pending tasks
    public List<Task> getPendingTasks() {
        return tasks.values().stream()
                .filter(task -> !task.isCompleted())
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
    }
}






package com.todoapp;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {
    
    @Autowired
    private TaskService taskService;
    
    // Get all tasks
    @GetMapping
    public ResponseEntity<List<Task>> getAllTasks() {
        List<Task> tasks = taskService.getAllTasks();
        return ResponseEntity.ok(tasks);
    }
    
    // Get task by ID
    @GetMapping("/{id}")
    public ResponseEntity<Task> getTaskById(@PathVariable Long id) {
        return taskService.getTaskById(id)
                .map(task -> ResponseEntity.ok(task))
                .orElse(ResponseEntity.notFound().build());
    }
    
    // Create new task
    @PostMapping
    public ResponseEntity<Task> createTask(@RequestBody Task task) {
        if (task.getTitle() == null || task.getTitle().trim().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        Task createdTask = taskService.createTask(task);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdTask);
    }
    
    // Update task
    @PutMapping("/{id}")
    public ResponseEntity<Task> updateTask(@PathVariable Long id, @RequestBody Task task) {
        return taskService.updateTask(id, task)
                .map(updatedTask -> ResponseEntity.ok(updatedTask))
                .orElse(ResponseEntity.notFound().build());
    }
    
    // Delete task
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteTask(@PathVariable Long id) {
        Map<String, String> response = new HashMap<>();
        if (taskService.deleteTask(id)) {
            response.put("message", "Task deleted successfully");
            return ResponseEntity.ok(response);
        } else {
            response.put("error", "Task not found");
            return ResponseEntity.notFound().build();
        }
    }
    
    // Mark task as completed
    @PatchMapping("/{id}/complete")
    public ResponseEntity<Task> markAsCompleted(@PathVariable Long id) {
        return taskService.markAsCompleted(id)
                .map(task -> ResponseEntity.ok(task))
                .orElse(ResponseEntity.notFound().build());
    }
    
    // Get completed tasks
    @GetMapping("/completed")
    public ResponseEntity<List<Task>> getCompletedTasks() {
        List<Task> tasks = taskService.getCompletedTasks();
        return ResponseEntity.ok(tasks);
    }
    
    // Get pending tasks
    @GetMapping("/pending")
    public ResponseEntity<List<Task>> getPendingTasks() {
        List<Task> tasks = taskService.getPendingTasks();
        return ResponseEntity.ok(tasks);
    }
    
    // Health check endpoint
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Todo API is running");
        return ResponseEntity.ok(response);
    }
}